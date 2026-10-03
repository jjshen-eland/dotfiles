#!/usr/bin/env python3
"""Read-only test-result/input comparison; no test execution or persistent cache.

check reads an existing JSON result (or temporary normalization of tool evidence):
command, exit, output (or stdout + stderr), inputs, and tested_commit or input_snapshot.
snapshot emits inputs/input_snapshot for an actual test's before/after comparison.
Optional environment maps are compared with --environment (current JSON facts).
The caller owns provenance, complete input selection and environment applicability.
Python 3.9+; standard library and Git only.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys


class Unusable(ValueError):
    pass


def inputs(value):
    if not isinstance(value, list) or not value:
        raise Unusable("missing input scope")
    for name in value:
        if (not isinstance(name, str) or not name or name.startswith(("/", ":"))
                or ".." in PurePosixPath(name).parts or "\x00" in name
                or ".git" in PurePosixPath(name).parts):
            raise Unusable("inputs must be literal repo-relative paths outside .git")
    return sorted(set(str(PurePosixPath(name)) for name in value))


def git(root, *args):
    return subprocess.run(["git", "--literal-pathspecs", "-C", str(root), *args],
                          capture_output=True, check=True).stdout


def snapshot(root, scope):
    result = {}

    def visit(path, name, ancestors):
        real = path.resolve(strict=True)
        if real in ancestors:
            raise Unusable("cyclic input symlink: " + name)
        link = os.fsencode(os.readlink(path)) if path.is_symlink() else b""
        if path.is_dir():
            result[name + "/"] = "directory:" + hashlib.sha256(link).hexdigest()
            for child in sorted(path.iterdir()):
                if child.name != ".git":
                    visit(child, str(PurePosixPath(name) / child.name), ancestors | {real})
        elif path.is_file():
            digest = hashlib.sha256()
            digest.update(link + b"\0")
            # Permission changes that affect execution are inputs too.
            digest.update(str(path.stat().st_mode & 0o111).encode() + b"\0")
            with path.open("rb") as stream:
                for block in iter(lambda: stream.read(1024 * 1024), b""):
                    digest.update(block)
            result[name] = digest.hexdigest()
        else:
            raise Unusable("unsupported input type: " + name)

    for name in scope:
        path = root / name
        if path.exists() or path.is_symlink():
            visit(path, name, set())
        else:
            result[name] = "absent"
    return result


def check(root, record, current_environment):
    if (not isinstance(record, dict)
            or not isinstance(record.get("command"), str) or not record["command"].strip()
            or type(record.get("exit")) is not int or record["exit"] != 0
            or not (isinstance(record.get("output"), str)
                    or all(isinstance(record.get(key), str) for key in ("stdout", "stderr")))):
        raise Unusable("missing or unsuccessful execution result; a summary is not test evidence")
    scope = inputs(record.get("inputs"))
    environment = record.get("environment")
    if environment is not None:
        if not isinstance(environment, dict) or environment != current_environment:
            raise Unusable("recorded environment missing from current facts or changed")
    elif current_environment is not None:
        raise Unusable("no recorded environment facts to compare")

    if "input_snapshot" in record:
        prior = record["input_snapshot"]
        if not isinstance(prior, dict) or not prior or not all(
                isinstance(k, str) and isinstance(v, str) for k, v in prior.items()):
            raise Unusable("invalid original input snapshot")
        now = snapshot(root, scope)
        changed = sorted(k for k in set(prior) | set(now) if prior.get(k) != now.get(k))
    else:
        anchor = record.get("tested_commit")
        if not isinstance(anchor, str) or not re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", anchor):
            raise Unusable("no immutable tested commit or original input snapshot")
        try:
            git(root, "cat-file", "-e", anchor + "^{commit}")
        except subprocess.CalledProcessError:
            raise Unusable("tested commit unavailable locally")
        tree = git(root, "ls-tree", "-r", "-z", anchor, "--", *scope)
        if any(entry.startswith((b"120000 ", b"160000 ")) for entry in tree.split(b"\0")):
            raise Unusable("Git anchor alone does not cover symlink targets/submodules; locate original content evidence")
        changed = git(root, "diff", "--no-ext-diff", "--no-renames", "--name-only", "-z",
                      anchor, "--", *scope).split(b"\0")
        # Include ignored files: an ignore rule does not prove a file is not an input.
        changed += git(root, "ls-files", "--others", "-z", "--", *scope).split(b"\0")
        changed = sorted({os.fsdecode(name) for name in changed if name})
    return {"verdict": "NEED_TEST" if changed else "REUSE", "command": record["command"],
            "inputs": scope, "changed_inputs": changed,
            "reason": "test inputs changed" if changed else "successful result and declared inputs match",
            "environment": "matched" if environment is not None else "caller must verify applicability"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["check", "snapshot"])
    parser.add_argument("--root", required=True)
    parser.add_argument("--evidence", help="existing JSON result, or - for normalized tool evidence on stdin")
    parser.add_argument("--input", action="append", help="literal path; repeat for snapshot scope")
    parser.add_argument("--environment", help="current environment facts as a JSON object")
    args = parser.parse_args()
    try:
        root = Path(args.root).resolve(strict=True)
        if Path(os.fsdecode(git(root, "rev-parse", "--show-toplevel")).strip()).resolve() != root:
            raise ValueError("--root must be the repository root")
        if args.action == "snapshot":
            scope = inputs(args.input)
            result = {"inputs": scope, "input_snapshot": snapshot(root, scope)}
        else:
            if not args.evidence:
                raise ValueError("check requires --evidence")
            raw = sys.stdin.read() if args.evidence == "-" else Path(args.evidence).read_text()
            environment = json.loads(args.environment) if args.environment else None
            if environment is not None and not isinstance(environment, dict):
                raise ValueError("--environment must be a JSON object")
            result = check(root, json.loads(raw), environment)
        status = 1 if result.get("verdict") == "NEED_TEST" else 0
    except Unusable as exc:
        result, status = {"verdict": "NEED_TEST", "reason": str(exc)}, 1
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as exc:
        result, status = {"verdict": "ERROR", "reason": str(exc)}, 2
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return status


if __name__ == "__main__":
    sys.exit(main())
