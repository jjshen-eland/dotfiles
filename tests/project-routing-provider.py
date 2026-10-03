#!/usr/bin/env python3
"""Local-only provider fixture for Project routing native evals, never real gh.

An unmatched query fails loudly. This fixture is not a GitHub integration test.
"""

import json
import pathlib
import subprocess
import sys


def main():
    root = pathlib.Path(__file__).resolve().parent
    args = sys.argv[1:]
    with (root / "provider-calls.jsonl").open("a") as log:
        log.write(json.dumps(args) + "\n")
    case = (root / "provider-case").read_text().strip()
    slug = "fixture-invalid/project-routing"
    url = "https://example.invalid/project-routing/pull/7"
    if args[:2] == ["repo", "view"]:
        if "nameWithOwner" in args:
            print(slug)
        elif "viewerPermission" in args:
            print("ADMIN")
        else:
            return 2
        return 0
    if args[:1] == ["api"]:
        endpoint = args[-1]
        if endpoint.endswith("/protection"):
            print(json.dumps({"required_status_checks": {"contexts": ["unit-tests"]}}))
        elif "rules/branches/" in endpoint:
            print("[]")
        else:
            return 2
        return 0
    if args[:2] == ["pr", "list"]:
        print("[]")
        return 0
    if args[:2] == ["pr", "view"]:
        if case == "ship-pr" and not (root / "pr-created").exists():
            print("no pull requests found", file=sys.stderr)
            return 1
        head = subprocess.check_output(
            ["git", "-C", str(root / "work"), "rev-parse", "HEAD"], text=True
        ).strip()
        data = {"url": url, "state": "OPEN", "number": 7,
                "mergeStateStatus": "BLOCKED", "mergeable": "MERGEABLE", "headRefOid": head}
        fields = args[args.index("--json") + 1].split(",") if "--json" in args else []
        for flag in ("-q", "--jq"):
            if flag in args:
                field = args[args.index(flag) + 1].lstrip(".")
                if field not in data:
                    return 2
                print(data[field])
                return 0
        print(json.dumps({field: data[field] for field in fields}) if fields else url)
        return 0
    if args[:2] == ["pr", "create"] and case == "ship-pr":
        (root / "pr-created").touch()
        print(url)
        return 0
    if args[:2] == ["pr", "checks"] and case == "merge-query":
        observations = root / "checks-count"
        count = int(observations.read_text()) if observations.exists() else 0
        observations.write_text(str(count + 1))
        if count == 0 and "--watch" not in args:
            print("unit-tests\tpending\t0\thttps://example.invalid/check/1")
            return 8
        print('Post "https://api.github.com/graphql": fixture transport error', file=sys.stderr)
        return 1
    print("fixture provider: unsupported operation: " + repr(args), file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
