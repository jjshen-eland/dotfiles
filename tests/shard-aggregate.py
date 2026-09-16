#!/usr/bin/env python3
"""Fail-closed aggregation for tests/run-parallel.sh shard artifacts."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


SUMMARY_RE = re.compile(
    r"^SHARD_RESULT name=(?P<name>[a-z_]+) pass=(?P<passed>[0-9]+) "
    r"fail=(?P<failed>[0-9]+) elapsed_s=(?P<elapsed>[0-9]+)$"
)
NAME_RE = re.compile(r"^[a-z_]+$")


def load_manifest(path: Path) -> dict[str, int]:
    shards: dict[str, int] = {}
    for line_number, raw_line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        fields = line.split("\t")
        if len(fields) != 2:
            raise ValueError(f"{path}:{line_number}: expected <shard><tab><pass-count>")
        name, raw_count = fields
        if not NAME_RE.fullmatch(name):
            raise ValueError(f"{path}:{line_number}: invalid shard name {name!r}")
        if name in shards:
            raise ValueError(f"{path}:{line_number}: duplicate shard {name!r}")
        try:
            count = int(raw_count)
        except ValueError as error:
            raise ValueError(
                f"{path}:{line_number}: invalid pass count {raw_count!r}"
            ) from error
        if count < 1:
            raise ValueError(f"{path}:{line_number}: pass count must be positive")
        shards[name] = count
    if not shards:
        raise ValueError(f"{path}: manifest is empty")
    return shards


def aggregate(manifest: Path, results: Path) -> tuple[int, list[str]]:
    errors: list[str] = []
    try:
        shards = load_manifest(manifest)
    except (OSError, ValueError) as error:
        return 0, [f"manifest: {error}"]

    if not results.is_dir():
        return 0, [f"results: directory does not exist: {results}"]

    expected_artifacts = {
        f"{name}.{suffix}" for name in shards for suffix in ("log", "rc")
    }
    actual_artifacts = {
        path.name for path in results.iterdir() if path.suffix in {".log", ".rc"}
    }
    unexpected = sorted(actual_artifacts - expected_artifacts)
    if unexpected:
        errors.append(f"results: unexpected artifacts: {', '.join(unexpected)}")

    total_passed = 0
    for name, expected_passed in shards.items():
        rc_path = results / f"{name}.rc"
        log_path = results / f"{name}.log"
        if not rc_path.is_file():
            errors.append(f"{name}: missing completion artifact {rc_path.name}")
            continue
        if not log_path.is_file():
            errors.append(f"{name}: missing diagnostic log {log_path.name}")
            continue

        try:
            raw_rc = rc_path.read_text(encoding="utf-8").strip()
            if not re.fullmatch(r"[0-9]+", raw_rc):
                raise ValueError(f"invalid child exit {raw_rc!r}")
            child_rc = int(raw_rc)
            log_lines = log_path.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeError, ValueError) as error:
            errors.append(f"{name}: unreadable result: {error}")
            continue

        if child_rc != 0:
            errors.append(f"{name}: child exited {child_rc}")

        summaries = [match for line in log_lines if (match := SUMMARY_RE.fullmatch(line))]
        if len(summaries) != 1:
            errors.append(f"{name}: expected exactly one SHARD_RESULT, found {len(summaries)}")
            continue
        summary = summaries[0].groupdict()
        if summary["name"] != name:
            errors.append(
                f"{name}: summary identity mismatch ({summary['name']!r})"
            )
        passed = int(summary["passed"])
        failed = int(summary["failed"])
        if passed != expected_passed:
            errors.append(
                f"{name}: assertion count mismatch (expected {expected_passed}, got {passed})"
            )
        if failed != 0:
            errors.append(f"{name}: shard reported {failed} failed assertions")
        total_passed += passed

    return total_passed, errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--results", required=True, type=Path)
    args = parser.parse_args()

    total_passed, errors = aggregate(args.manifest, args.results)
    if errors:
        for error in errors:
            print(f"SHARD_AGGREGATE_ERROR {error}", file=sys.stderr)
        return 1

    shard_count = len(load_manifest(args.manifest))
    print(f"SHARD_AGGREGATE pass={total_passed} fail=0 shards={shard_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
