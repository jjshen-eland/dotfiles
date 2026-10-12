#!/usr/bin/env python3
"""Grade a recipient's handover acceptance answers against the giver's grading spec.

usage: grade-handover.py --spec <transfer-acceptance.json> --answers <answers.json> --clone <fresh-clone>

Run only against a disposable fresh clone: `command` questions execute the recipient's answer there.
Exit 0 = every question passed, 1 = at least one failed, 2 = malformed input (verdict: BROKEN).
"""

import argparse
import json
import pathlib
import subprocess
import sys

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
        elif "stdout_contains" in question and not isinstance(question["stdout_contains"], str):
            broken(f"{qid}: stdout_contains must be a string")


def grade_command(question, answer, clone):
    result = subprocess.run(answer, shell=True, cwd=clone, capture_output=True, text=True)
    if result.returncode != 0:
        return f"command exited {result.returncode}"
    expected = question.get("stdout_contains")
    if expected and expected not in result.stdout:
        return f"output lacks {expected!r}"
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
    args = parser.parse_args()
    spec = load(args.spec, "spec")
    validate(spec)
    answers = load(args.answers, "answers")
    if not isinstance(answers, dict):
        broken("answers must be an object of id -> answer")
    clone = pathlib.Path(args.clone)
    if not clone.is_dir():
        broken("clone directory does not exist")
    failed = 0
    for question in spec["questions"]:
        qid = question["id"]
        answer = answers.get(qid)
        if not isinstance(answer, str) or not answer.strip():
            problem = "unanswered"
        elif question["kind"] == "command":
            problem = grade_command(question, answer, clone)
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
