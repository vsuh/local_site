#!/usr/bin/env python3
"""Publish local TCP port health checks as a JSON file for the dashboard."""

import argparse
import json
import os
import socket
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


def check_service(service_id, service, timeout, interval):
    port_value = str(service.get("port", "")).strip()
    if not port_value:
        url = str(service.get("link", "")).strip()
        if not url:
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
            parsed_url = urllib.parse.urlsplit(url)
            if parsed_url.scheme not in ("http", "https") or not parsed_url.netloc:
                raise ValueError("external link must be an absolute HTTP(S) URL")
            request = urllib.request.Request(
                url,
                headers={"User-Agent": "local-site-healthcheck/1.0"},
            )
            with urllib.request.urlopen(request, timeout=timeout) as response:
                status_code = response.status
            elapsed_ms = round((time.monotonic() - started) * 1000)
            status = "online" if 200 <= status_code < 400 else "offline"
            result = {
                "name": service.get("name", service_id),
                "port": None,
                "url": url,
                "status": status,
                "status_code": status_code,
                "checked_at": utc_now(),
                "response_time_ms": elapsed_ms,
                "interval_seconds": interval,
                "timeout_seconds": timeout,
            }
            if status == "offline":
                result["error"] = f"HTTP {status_code}"
            return service_id, result
        except urllib.error.HTTPError as error:
            elapsed_ms = round((time.monotonic() - started) * 1000)
            return service_id, {
                "name": service.get("name", service_id),
                "port": None,
                "url": url,
                "status": "offline",
                "status_code": error.code,
                "checked_at": utc_now(),
                "response_time_ms": elapsed_ms,
                "error": f"HTTP {error.code}",
                "interval_seconds": interval,
                "timeout_seconds": timeout,
            }
        except (OSError, ValueError, urllib.error.URLError) as error:
            return service_id, {
                "name": service.get("name", service_id),
                "port": None,
                "url": url,
                "status": "offline",
                "checked_at": utc_now(),
                "error": str(error),
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
                interval = max(1.0, float(service.get("interval_seconds", default_interval)))
                timeout = max(0.1, float(service.get("timeout_seconds", default_timeout)))
                signature = (
                    str(service.get("name", service_id)),
                    str(service.get("port", "")).strip(),
                    str(service.get("health_host", "127.0.0.1")),
                    str(service.get("link", "")).strip(),
                    interval,
                    timeout,
                )
                previous_signature = service_signatures.get(service_id)
                if previous_signature is not None and previous_signature != signature:
                    results.pop(service_id, None)
                    last_checked.pop(service_id, None)
                service_signatures[service_id] = signature

                if service_id not in results or now - last_checked.get(service_id, 0) >= interval:
                    due.append((service_id, service, timeout, interval))

            if due:
                workers = max(1, min(32, len(due)))
                with ThreadPoolExecutor(max_workers=workers) as pool:
                    futures = {
                        pool.submit(check_service, service_id, service, timeout, interval):
                        (service_id, interval)
                        for service_id, service, timeout, interval in due
                    }
                    for future in as_completed(futures):
                        service_id, _interval = futures[future]
                        result_id, result = future.result()
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG, help="path to src/site.json")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="path to the web-served health.json")
    parser.add_argument("--once", action="store_true", help="run one check and exit")
    args = parser.parse_args()
    run(args.config, args.output, once=args.once)


if __name__ == "__main__":
    main()
