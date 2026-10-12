#!/usr/bin/env python3
"""Grade a recipient's handover acceptance answers against the giver's grading spec.

usage: grade-handover.py --spec <transfer-acceptance.json> --answers <answers.json> --clone <fresh-clone>
                         [--allow-exec] [--timeout SECONDS]

`command` answers are recipient-supplied shell commands. Without --allow-exec they are only listed
(exit 3, verdict: NEEDS_CONFIRMATION) so the giver can check they are read-only local checks first.
With --allow-exec each runs in the clone with a minimal environment (no caller variables, a throwaway
HOME, no stdin) and a timeout. Run only against a disposable clone.
Exit 0 = every question passed, 1 = at least one failed, 2 = malformed input, 3 = confirmation needed.
"""

import argparse
import json
import os
import pathlib
import subprocess
import sys
import tempfile

KINDS = {"command", "answer"}


def broken(reason):
    print(f"reason: {reason}")
    print("verdict: BROKEN")
    sys.exit(2)


def load(path, what):
    try:
        return json.loads(pathlib.Path(path).read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        broken(f"{what} unreadable: {exc}")


def string_list(question, key):
    value = question.get(key, [])
    if not isinstance(value, list) or not all(isinstance(item, str) and item for item in value):
        broken(f"{question.get('id')}: {key} must be a list of non-empty strings")
    return value


def validate(spec):
    if not isinstance(spec, dict) or spec.get("schema") != 1 or not isinstance(spec.get("questions"), list):
        broken("spec must be {\"schema\": 1, \"questions\": [...]}")
    if not spec["questions"]:
        broken("spec has no questions")
    seen = set()
    for question in spec["questions"]:
        if not isinstance(question, dict):
            broken("each question must be an object")
        qid = question.get("id")
        if not isinstance(qid, str) or not qid or qid in seen:
            broken(f"question id missing or duplicated: {qid!r}")
        seen.add(qid)
        if question.get("kind") not in KINDS:
            broken(f"{qid}: kind must be one of {sorted(KINDS)}")
        if question["kind"] == "answer":
            checks = [string_list(question, key) for key in ("contains", "paths", "ids")]
            if not any(checks):
                broken(f"{qid}: answer question needs contains, paths or ids")
            for rel in checks[1]:
                parts = pathlib.PurePosixPath(rel).parts
                if rel.startswith("/") or ".." in parts:
                    broken(f"{qid}: path must stay inside the clone: {rel}")
        else:
            expected = question.get("stdout_contains")
            if not isinstance(expected, str) or not expected:
                broken(f"{qid}: command question needs a non-empty stdout_contains")


def grade_command(question, answer, clone, timeout, home):
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": home, "LANG": "C.UTF-8", "LC_ALL": "C.UTF-8"}
    try:
        result = subprocess.run(answer, shell=True, cwd=clone, env=env, stdin=subprocess.DEVNULL,
                                capture_output=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return f"timed out after {timeout}s"
    if result.returncode != 0:
        return f"command exited {result.returncode}"
    if question["stdout_contains"] not in result.stdout.decode("utf-8", errors="replace"):
        return f"output lacks {question['stdout_contains']!r}"
    return None


def grade_answer(question, answer, clone):
    for text in question.get("contains", []) + question.get("ids", []):
        if text not in answer:
            return f"answer lacks {text!r}"
    for rel in question.get("paths", []):
        if rel not in answer:
            return f"answer does not cite {rel}"
        if not (clone / rel).exists():
            return f"{rel} does not exist in the clone"
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", required=True)
    parser.add_argument("--answers", required=True)
    parser.add_argument("--clone", required=True)
    parser.add_argument("--allow-exec", action="store_true")
    parser.add_argument("--timeout", type=int, default=300)
    args = parser.parse_args()
    spec = load(args.spec, "spec")
    validate(spec)
    answers = load(args.answers, "answers")
    if not isinstance(answers, dict):
        broken("answers must be an object of id -> answer")
    clone = pathlib.Path(args.clone).resolve()
    if not clone.is_dir():
        broken("clone directory does not exist")
    commands = [(q["id"], answers.get(q["id"])) for q in spec["questions"] if q["kind"] == "command"]
    if commands and not args.allow_exec:
        for qid, answer in commands:
            print(f"{qid}: COMMAND {answer!r}")
        print("reason: command answers run only after the giver checks they are read-only local checks")
        print("verdict: NEEDS_CONFIRMATION")
        sys.exit(3)
    failed = 0
    with tempfile.TemporaryDirectory(prefix="handover-home-") as home:
        for question in spec["questions"]:
            qid = question["id"]
            answer = answers.get(qid)
            if not isinstance(answer, str) or not answer.strip():
                problem = "unanswered"
            elif question["kind"] == "command":
                problem = grade_command(question, answer, clone, args.timeout, home)
            else:
                problem = grade_answer(question, answer, clone)
            if problem:
                failed += 1
                print(f"{qid}: FAIL ({problem})")
            else:
                print(f"{qid}: PASS")
    print(f"passed: {len(spec['questions']) - failed}/{len(spec['questions'])}")
    print("verdict: " + ("FAIL" if failed else "PASS"))
    sys.exit(1 if failed else 0)


main()
