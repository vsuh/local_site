#!/usr/bin/env python3
"""Publish local TCP port health checks as a JSON file for the dashboard."""

import argparse
import json
import os
import socket
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG = ROOT / "src" / "site.json"
DEFAULT_OUTPUT = ROOT / "static" / "health.json"


def utc_now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def check_service(service_id, service, timeout):
    port_value = str(service.get("port", "")).strip()
    if not port_value:
        return service_id, {
            "name": service.get("name", service_id),
            "port": None,
            "status": "external",
            "checked_at": utc_now(),
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
        }
    except (OSError, ValueError) as error:
        return service_id, {
            "name": service.get("name", service_id),
            "port": port_value,
            "host": str(service.get("health_host", "127.0.0.1")),
            "status": "offline",
            "checked_at": utc_now(),
            "error": str(error),
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
    while True:
        started = time.monotonic()
        try:
            with config_path.open("r", encoding="utf-8") as source:
                config = json.load(source)["site"]
            settings = config.get("healthcheck", {})
            interval = max(1.0, float(settings.get("interval_seconds", 30)))
            timeout = max(0.1, float(settings.get("timeout_seconds", 3)))
            services = config.get("container", {}).get("links", {})
            results = {}
            workers = max(1, min(32, len(services) or 1))
            with ThreadPoolExecutor(max_workers=workers) as pool:
                futures = [
                    pool.submit(check_service, service_id, service, timeout)
                    for service_id, service in services.items()
                ]
                for future in as_completed(futures):
                    service_id, result = future.result()
                    results[service_id] = result
            payload = {
                "updated_at": utc_now(),
                "interval_seconds": interval,
                "timeout_seconds": timeout,
                "services": results,
            }
            write_json_atomic(output_path, payload)
            print(f"[{payload['updated_at']}] wrote {len(results)} service statuses to {output_path}", flush=True)
        except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
            print(f"Health check failed: {error}", flush=True)
            if once:
                raise
            interval = 30

        if once:
            return
        remaining = max(0.0, interval - (time.monotonic() - started))
        time.sleep(remaining)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG, help="path to src/site.json")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="path to the web-served health.json")
    parser.add_argument("--once", action="store_true", help="run one check and exit")
    args = parser.parse_args()
    run(args.config, args.output, once=args.once)


if __name__ == "__main__":
    main()
