#!/usr/bin/env python3
"""Send one bounded wait4me notification without exposing transport errors."""

from __future__ import annotations

import json
import os
import sys
import urllib.request


ALLOWED_LEVELS = {"info", "warning", "error"}
TASK = "agent-response-needed"


def safe_warning(kind: str) -> None:
    print(f"wait4me: notification skipped ({kind})", file=sys.stderr)


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


def main() -> int:
    payload = load_payload()
    if payload is None:
        return 0

    capture_path = os.environ.get("WAIT4ME_TEST_CAPTURE")
    if capture_path:
        try:
            capture(payload, capture_path)
        except OSError:
            safe_warning("capture-failed")
        return 0

    url = os.environ.get("NC_API_URL")
    api_key = os.environ.get("NC_API_KEY")
    if not url or not api_key:
        return 0

    try:
        if os.environ.get("WAIT4ME_TEST_ERROR"):
            raise RuntimeError("synthetic transport failure")
        body = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode()
        request = urllib.request.Request(
            url,
            data=body,
            method="POST",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
        )
        with urllib.request.urlopen(request, timeout=3) as response:
            response.read(1)
    except Exception as error:  # Notification failure must never escape into the hook.
        safe_warning(type(error).__name__)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
