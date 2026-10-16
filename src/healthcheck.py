#!/usr/bin/env python3
"""Publish local TCP port health checks as a JSON file for the dashboard."""

import argparse
import http.client
import ipaddress
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG = ROOT / "src" / "site.json"
DEFAULT_OUTPUT = ROOT / "static" / "health.json"


def utc_now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def validate_public_http_url(url, timeout):
    """Reject non-HTTP URLs and hosts resolving to non-public IP addresses."""
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme not in ("http", "https") or not parsed.hostname:
        raise ValueError("external link must be an absolute HTTP(S) URL")
    if parsed.username is not None or parsed.password is not None:
        raise ValueError("external link must not contain credentials")
    try:
        port = parsed.port
    except ValueError as error:
        raise ValueError("external link has an invalid port") from error
    port = port or (443 if parsed.scheme == "https" else 80)

    try:
        address = ipaddress.ip_address(parsed.hostname)
        addresses = [address]
    except ValueError:
        # The worker process is bounded by the parent process's wall-clock
        # timeout, including this DNS lookup.
        records = socket.getaddrinfo(parsed.hostname, port, type=socket.SOCK_STREAM)
        addresses = [ipaddress.ip_address(record[4][0]) for record in records]

    if not addresses or any(not address.is_global for address in addresses):
        raise ValueError("external URL resolves to a non-public IP address")
    return parsed


class PublicOnlyRedirectHandler(urllib.request.HTTPRedirectHandler):
    def __init__(self, timeout):
        super().__init__()
        self.timeout = timeout

    def redirect_request(self, request, response, code, message, headers, new_url):
        validate_public_http_url(new_url, self.timeout)
        return super().redirect_request(request, response, code, message, headers, new_url)


def external_http_worker(url, timeout):
    """Run inside an isolated process so DNS and socket stalls have a hard deadline."""
    started = time.monotonic()
    try:
        validate_public_http_url(url, timeout)
        request = urllib.request.Request(
            url,
            headers={"User-Agent": "local-site-healthcheck/1.0"},
        )
        opener = urllib.request.build_opener(PublicOnlyRedirectHandler(timeout))
        with opener.open(request, timeout=timeout) as response:
            status_code = response.status
        status = "online" if 200 <= status_code < 400 else "offline"
        result = {"status": status, "status_code": status_code}
        if status == "offline":
            result["error"] = f"HTTP {status_code}"
    except urllib.error.HTTPError as error:
        # urllib may surface a 3xx response as HTTPError when it cannot follow
        # that particular redirect; documented 3xx responses are still online.
        result = {
            "status": "online" if 300 <= error.code < 400 else "offline",
            "status_code": error.code,
        }
        if result["status"] == "offline":
            result["error"] = f"HTTP {error.code}"
    except (http.client.HTTPException, OSError, ValueError, urllib.error.URLError) as error:
        result = {"status": "offline", "error": str(error)}
    result["response_time_ms"] = round((time.monotonic() - started) * 1000)
    return result


def check_service(service_id, service, timeout, interval):
    port_value = str(service.get("port", "")).strip()
    if not port_value:
        url = str(service.get("link", "")).strip()
        if not is_absolute_http_url(url):
            return service_id, {
                "name": service.get("name", service_id),
                "port": None,
                "status": "external",
                "checked_at": utc_now(),
                "interval_seconds": interval,
                "timeout_seconds": timeout,
            }

        started = time.monotonic()
        try:
            # subprocess.run's timeout is a wall-clock deadline covering process
            # startup, DNS resolution, connection, TLS, redirects and response.
            completed = subprocess.run(
                [
                    sys.executable,
                    str(Path(__file__).resolve()),
                    "--http-worker",
                    url,
                    str(timeout),
                ],
                check=True,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            checked = json.loads(completed.stdout)
        except subprocess.TimeoutExpired:
            checked = {
                "status": "offline",
                "error": f"HTTP check exceeded {timeout:g}s deadline",
            }
        except (http.client.HTTPException, OSError, subprocess.SubprocessError, ValueError, json.JSONDecodeError) as error:
            checked = {"status": "offline", "error": str(error)}

        elapsed_ms = round((time.monotonic() - started) * 1000)
        return service_id, {
            "name": service.get("name", service_id),
            "port": None,
            "url": url,
            "status": checked.get("status", "offline"),
            "status_code": checked.get("status_code"),
            "checked_at": utc_now(),
            "response_time_ms": checked.get("response_time_ms", elapsed_ms),
            **({"error": checked["error"]} if checked.get("error") else {}),
            "interval_seconds": interval,
            "timeout_seconds": timeout,
        }

    try:
        port = int(port_value)
        if not 1 <= port <= 65535:
            raise ValueError("port must be between 1 and 65535")
        target_host = str(service.get("health_host", "127.0.0.1"))
        started = time.monotonic()
        with socket.create_connection((target_host, port), timeout=timeout):
            elapsed_ms = round((time.monotonic() - started) * 1000)
        return service_id, {
            "name": service.get("name", service_id),
            "port": port,
            "host": target_host,
            "status": "online",
            "checked_at": utc_now(),
            "response_time_ms": elapsed_ms,
            "interval_seconds": interval,
            "timeout_seconds": timeout,
        }
    except (OSError, ValueError) as error:
        return service_id, {
            "name": service.get("name", service_id),
            "port": port_value,
            "host": str(service.get("health_host", "127.0.0.1")),
            "status": "offline",
            "checked_at": utc_now(),
            "error": str(error),
            "interval_seconds": interval,
            "timeout_seconds": timeout,
        }


def is_absolute_http_url(url):
    try:
        parsed = urllib.parse.urlsplit(url)
        if parsed.scheme not in ("http", "https") or not parsed.hostname or not parsed.netloc:
            return False
        if parsed.username is not None or parsed.password is not None:
            return False
        # Accessing .port also validates the explicit port syntax.
        parsed.port
        return True
    except ValueError:
        return False


def service_signature(service_id, service, default_interval, default_timeout):
    interval = max(1.0, float(service.get("interval_seconds", default_interval)))
    timeout = max(0.1, float(service.get("timeout_seconds", default_timeout)))
    return (
        str(service.get("name", service_id)),
        str(service.get("port", "")).strip(),
        str(service.get("health_host", "127.0.0.1")),
        str(service.get("link", "")).strip(),
        interval,
        timeout,
    )


def write_json_atomic(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    handle = tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=path.parent,
        prefix=f".{path.name}.", suffix=".tmp", delete=False
    )
    temporary_path = Path(handle.name)
    try:
        with handle:
            json.dump(payload, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        os.replace(temporary_path, path)
    finally:
        if temporary_path.exists():
            temporary_path.unlink()


def run(config_path, output_path, once=False):
    last_checked = {}
    results = {}
    service_signatures = {}

    while True:
        try:
            with config_path.open("r", encoding="utf-8") as source:
                config = json.load(source)["site"]
            settings = config.get("healthcheck", {})
            default_interval = max(1.0, float(settings.get("interval_seconds", 30)))
            default_timeout = max(0.1, float(settings.get("timeout_seconds", 3)))
            services = config.get("container", {}).get("links", {})
            active_ids = set(services)
            results = {key: value for key, value in results.items() if key in active_ids}
            last_checked = {key: value for key, value in last_checked.items() if key in active_ids}
            service_signatures = {
                key: value for key, value in service_signatures.items() if key in active_ids
            }
            now = time.monotonic()
            due = []

            for service_id, service in services.items():
                signature = service_signature(service_id, service, default_interval, default_timeout)
                interval, timeout = signature[-2:]
                previous_signature = service_signatures.get(service_id)
                if previous_signature is not None and previous_signature != signature:
                    results.pop(service_id, None)
                    last_checked.pop(service_id, None)
                service_signatures[service_id] = signature

                if service_id not in results or now - last_checked.get(service_id, 0) >= interval:
                    due.append((service_id, service, timeout, interval, signature))

            if due:
                workers = max(1, min(32, len(due)))
                with ThreadPoolExecutor(max_workers=workers) as pool:
                    futures = {
                        pool.submit(check_service, service_id, service, timeout, interval):
                        (service_id, signature)
                        for service_id, service, timeout, interval, signature in due
                    }
                    for future in as_completed(futures):
                        service_id, checked_signature = futures[future]
                        result_id, result = future.result()

                        # Re-read the config before accepting a result: the service
                        # URL or settings may have changed while the check was running.
                        with config_path.open("r", encoding="utf-8") as source:
                            current_config = json.load(source)["site"]
                        current_settings = current_config.get("healthcheck", {})
                        current_default_interval = max(
                            1.0, float(current_settings.get("interval_seconds", 30))
                        )
                        current_default_timeout = max(
                            0.1, float(current_settings.get("timeout_seconds", 3))
                        )
                        current_services = current_config.get("container", {}).get("links", {})
                        current_service = current_services.get(service_id)
                        if current_service is None or service_signature(
                            service_id, current_service,
                            current_default_interval, current_default_timeout
                        ) != checked_signature:
                            results.pop(service_id, None)
                            last_checked.pop(service_id, None)
                            service_signatures.pop(service_id, None)
                            continue

                        results[result_id] = result
                        last_checked[result_id] = time.monotonic()

                payload = {
                    "updated_at": utc_now(),
                    "interval_seconds": default_interval,
                    "timeout_seconds": default_timeout,
                    "services": results,
                }
                write_json_atomic(output_path, payload)
                print(
                    f"[{payload['updated_at']}] checked {len(due)} services; "
                    f"published {len(results)} statuses to {output_path}",
                    flush=True,
                )

            if once:
                return

            # Re-read configuration regularly, but only check each service when its
            # own interval expires. This also picks up configuration changes quickly.
            next_due = []
            now = time.monotonic()
            for service_id, service in services.items():
                interval = max(1.0, float(service.get("interval_seconds", default_interval)))
                next_due.append(max(0.1, interval - (now - last_checked.get(service_id, now))))
            sleep_for = min([1.0, *next_due]) if next_due else 1.0
            time.sleep(sleep_for)

        except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
            print(f"Health check failed: {error}", flush=True)
            if once:
                raise
            time.sleep(1)


def main():
    if len(sys.argv) == 4 and sys.argv[1] == "--http-worker":
        print(json.dumps(external_http_worker(sys.argv[2], max(0.1, float(sys.argv[3])))))
        return

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG, help="path to src/site.json")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="path to the web-served health.json")
    parser.add_argument("--once", action="store_true", help="run one check and exit")
    args = parser.parse_args()
    run(args.config, args.output, once=args.once)


if __name__ == "__main__":
    main()
