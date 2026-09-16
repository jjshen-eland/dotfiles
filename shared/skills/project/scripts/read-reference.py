#!/usr/bin/env python3
"""Emit one bounded, verifiable chunk of a Project reference."""

from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path


DEFAULT_MAX_BYTES = 12_000
MIN_MAX_BYTES = 256


def positive_line(value: str) -> int:
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError("must be at least 1")
    return number


def byte_budget(value: str) -> int:
    number = int(value)
    if number < MIN_MAX_BYTES:
        raise argparse.ArgumentTypeError(
            f"must be at least {MIN_MAX_BYTES} bytes"
        )
    return number


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Read one shared Project reference in bounded line chunks."
    )
    parser.add_argument("reference", help="direct .md basename under references/")
    parser.add_argument("--start", type=positive_line, default=1)
    parser.add_argument("--max-bytes", type=byte_budget, default=DEFAULT_MAX_BYTES)
    return parser.parse_args()


def render(
    name: str,
    digest: str,
    total: int,
    start: int,
    numbered_lines: list[str],
) -> str:
    end = start + len(numbered_lines) - 1
    footer = f"EOF\t{total}" if end == total else f"NEXT\t{end + 1}"
    header = (
        f"REFERENCE\t{name}\n"
        f"SHA256\t{digest}\n"
        f"TOTAL\t{total}\n"
        f"RANGE\t{start}\t{end}\n"
        "BEGIN\n"
    )
    return header + "".join(numbered_lines) + f"END\n{footer}\n"


def main() -> int:
    args = parse_args()
    requested = Path(args.reference)
    if (
        requested.is_absolute()
        or requested.name != args.reference
        or requested.suffix != ".md"
        or args.reference in {".", ".."}
    ):
        print("reference must be a direct .md basename", file=sys.stderr)
        return 2

    references = Path(__file__).resolve().parent.parent / "references"
    target = references / requested
    if not target.is_file():
        print(f"reference not found: {args.reference}", file=sys.stderr)
        return 2

    raw = target.read_bytes()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as error:
        print(f"reference is not UTF-8: {error}", file=sys.stderr)
        return 2

    lines = text.splitlines()
    total = len(lines)
    if total == 0 or args.start > total:
        print(f"start must be within 1..{total}", file=sys.stderr)
        return 2

    digest = hashlib.sha256(raw).hexdigest()
    selected: list[str] = []
    for line_number in range(args.start, total + 1):
        candidate = selected + [f"L{line_number:06d}\t{lines[line_number - 1]}\n"]
        output = render(args.reference, digest, total, args.start, candidate)
        if len(output.encode("utf-8")) > args.max_bytes:
            break
        selected = candidate

    if not selected:
        print(
            "max-bytes cannot hold the next complete line and protocol envelope",
            file=sys.stderr,
        )
        return 1

    sys.stdout.write(render(args.reference, digest, total, args.start, selected))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
