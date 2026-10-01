#!/usr/bin/env python3
"""Send one bounded wait4me notification without exposing transport errors."""

from __future__ import annotations

import errno
import json
import os
import socket
import ssl
import stat
import subprocess
import sys


ALLOWED_LEVELS = {"info", "warning", "error"}
TASK = "agent-response-needed"
SOURCE = "agent-wait4me"
EVENT_TYPE = "alert"
DELIVERY_UNAVAILABLE = 75


def safe_warning(kind: str) -> None:
    print(f"wait4me: notification skipped ({kind})", file=sys.stderr)


def failure_kind(error: Exception) -> str:
    """Return a bounded diagnosis token, never an exception message or destination."""
    if isinstance(error, subprocess.TimeoutExpired):
        return "timeout"
    if isinstance(error, FileNotFoundError):
        return "curl-unavailable"
    if isinstance(error, socket.gaierror):
        return "dns-error"
    if isinstance(error, ssl.SSLError):
        return "tls-error"
    if isinstance(error, TimeoutError):
        return "timeout"
    if isinstance(error, OSError):
        if error.errno in {errno.EHOSTUNREACH, errno.ENETUNREACH}:
            return "network-unreachable"
        if error.errno == errno.ECONNREFUSED:
            return "connection-refused"
    return type(error).__name__


def curl_failure_kind(returncode: int, stderr: bytes) -> str:
    """Classify curl without exposing its verbose output, which includes auth headers."""
    if returncode == 22:
        return "http-error"
    if returncode in {5, 6}:
        return "dns-error"
    if returncode == 7:
        detail = stderr.lower()
        if b"no route to host" in detail or b"network is unreachable" in detail:
            return "network-unreachable"
        if b"connection refused" in detail:
            return "connection-refused"
        return "connect-failed"
    if returncode == 28:
        return "timeout"
    if returncode in {35, 51, 58, 59, 60, 77, 83}:
        return "tls-error"
    return "curl-error"


def curl_quote(value: str) -> str:
    if any(ord(character) < 32 or ord(character) == 127 for character in value):
        raise ValueError("invalid curl config value")
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def load_payload() -> dict[str, str] | None:
    try:
        value = json.load(sys.stdin)
    except (json.JSONDecodeError, UnicodeError):
        safe_warning("invalid-payload")
        return None

    if not isinstance(value, dict):
        safe_warning("invalid-payload")
        return None

    message = value.get("message")
    level = value.get("level")
    task = value.get("task")
    if (
        not isinstance(message, str)
        or not message
        or "\n" in message
        or "\r" in message
        or len(message) > 200
        or level not in ALLOWED_LEVELS
        or task != TASK
    ):
        safe_warning("invalid-payload")
        return None
    return {"message": message, "level": level, "task": task}


def capture(payload: dict[str, str], path: str) -> None:
    encoded = (json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n").encode()
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o600)
    with os.fdopen(fd, "ab") as stream:
        stream.write(encoded)


def load_env_file(path: str) -> dict[str, str]:
    """讀取兩個明示設定鍵；不執行shell語法或展開其他變數。"""
    descriptor: int | None = None
    try:
        descriptor = os.open(path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
        metadata = os.fstat(descriptor)
        if (
            not stat.S_ISREG(metadata.st_mode)
            or metadata.st_uid != os.getuid()
            or metadata.st_mode & 0o077
        ):
            safe_warning("unsafe-env-file")
            os.close(descriptor)
            return {}
        with os.fdopen(descriptor, encoding="utf-8") as stream:
            descriptor = None
            lines = stream.read().splitlines()
    except (OSError, UnicodeError):
        if descriptor is not None:
            os.close(descriptor)
        safe_warning("env-file-unavailable")
        return {}

    values: dict[str, str] = {}
    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.removeprefix("export ").strip()
        if key not in {"NC_API_URL", "NC_API_KEY"}:
            continue
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
            value = value[1:-1]
        if value:
            values[key] = value
    return values


def transport_config() -> tuple[str, str] | None:
    url = os.environ.get("NC_API_URL")
    api_key = os.environ.get("NC_API_KEY")
    env_path = os.environ.get("WAIT4ME_ENV_FILE")
    if (not url or not api_key) and env_path:
        values = load_env_file(env_path)
        url = url or values.get("NC_API_URL")
        api_key = api_key or values.get("NC_API_KEY")
    if not url or not api_key:
        safe_warning("missing-config")
        return None
    if len(api_key) > 4096 or any(ord(character) < 32 or ord(character) == 127 for character in api_key):
        safe_warning("invalid-config")
        return None
    return url, api_key


def main() -> int:
    payload = load_payload()
    if payload is None:
        return 0

    config = transport_config()
    if config is None:
        return DELIVERY_UNAVAILABLE
    base_url, api_key = config

    try:
        capture_path = os.environ.get("WAIT4ME_TEST_CAPTURE")
        if capture_path:
            capture(payload, capture_path)
            return 0
        if os.environ.get("WAIT4ME_TEST_ERROR"):
            raise RuntimeError("synthetic transport failure")
        gateway_url = base_url.rstrip("/") + "/api/v1/events"
        wire_payload = {
            "event_type": EVENT_TYPE,
            "source": SOURCE,
            "level": payload["level"],
            "message": payload["message"],
        }
        body = json.dumps(wire_payload, ensure_ascii=False, separators=(",", ":"))
        curl_config = "\n".join(
            [
                "header = " + curl_quote("X-API-Key: " + api_key),
                "header = " + curl_quote("Content-Type: application/json"),
                "data-binary = " + curl_quote(body),
            ]
        ) + "\n"
        response = subprocess.run(
            [
                "/usr/bin/curl", "-q", "--fail", "--silent", "--show-error", "--verbose",
                "--connect-timeout", "2", "--max-time", "3", "--proto", "=http,https",
                "--request", "POST", "--config", "-", "--url", gateway_url,
            ],
            input=curl_config.encode(),
            capture_output=True,
            timeout=4,
        )
        if response.returncode != 0:
            safe_warning(curl_failure_kind(response.returncode, response.stderr))
            return DELIVERY_UNAVAILABLE
        result = json.loads(response.stdout)
        if result.get("action_taken") not in {"forward", "escalate"} or result.get(
            "notification_status"
        ) not in {"sent", "deduplicated"}:
            safe_warning("delivery-unconfirmed")
            return DELIVERY_UNAVAILABLE
    except Exception as error:  # Notification failure must never escape into the hook.
        safe_warning(failure_kind(error))
        return DELIVERY_UNAVAILABLE
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
