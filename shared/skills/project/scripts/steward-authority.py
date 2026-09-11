#!/usr/bin/env python3
"""Resolve ordinary Project Log stewardship without model identity guesses.

Exit codes:
  0  authority PASS or active-item contract not enabled
  1  authority STOP (expected policy mismatch)
  2  usage, repository, config, or STATUS parse failure

This helper intentionally does not resolve PREPARED transfers. The shared
workflow must establish the effective durable steward from remote-visible
transfer evidence before using this ordinary-path gate.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

FIELD_RE = re.compile(
    r"^-\s+\*\*(Writer|Workspace|Write Scope|Dossier Steward)\*\*[：:]\s*(.*?)\s*$"
)
ACTOR_RE = re.compile(r"^(claude|codex|human|owner|external|unassigned):[^\s:][^\s]*$")
HUMAN_PREFIXES = ("human:", "owner:")
SHARED_EXACT = {"STATUS.md", "docs/backlog.md", "docs/transfer.md"}


@dataclass(frozen=True)
class ActiveItem:
    heading: str
    writer: str
    workspace: str
    steward: str


def fail(message: str, code: int = 2) -> int:
    print(f"error: {message}", file=sys.stderr)
    return code


def git(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        capture_output=True,
        check=False,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "git command failed")
    return result.stdout.strip()


def active_contract(config: dict) -> bool:
    schema = config.get("status_schema")
    return isinstance(schema, dict) and isinstance(schema.get("active_item_contract"), dict)


def active_items(status_text: str) -> list[ActiveItem]:
    in_active = False
    blocks: list[tuple[str, list[str]]] = []
    heading = ""
    body: list[str] = []

    for line in status_text.splitlines():
        if line.startswith("## "):
            if in_active and heading:
                blocks.append((heading, body))
            in_active = line[3:].strip().startswith("進行中")
            heading, body = "", []
            continue
        if not in_active:
            continue
        if line.startswith("### "):
            if heading:
                blocks.append((heading, body))
            heading, body = line[4:].strip(), []
        elif heading:
            body.append(line)

    if in_active and heading:
        blocks.append((heading, body))

    items: list[ActiveItem] = []
    for item_heading, lines in blocks:
        fields: dict[str, str] = {}
        for line in lines:
            match = FIELD_RE.match(line)
            if match:
                fields[match.group(1)] = match.group(2).strip().strip("`")
        if not fields:
            continue
        missing = [name for name in ("Writer", "Workspace", "Dossier Steward") if not fields.get(name)]
        if missing:
            raise ValueError(f"active item {item_heading!r} missing fields: {', '.join(missing)}")
        items.append(
            ActiveItem(
                heading=item_heading,
                writer=fields["Writer"],
                workspace=fields["Workspace"],
                steward=fields["Dossier Steward"],
            )
        )
    return items


def validate_actor(actor: str, label: str) -> None:
    if not ACTOR_RE.fullmatch(actor):
        raise ValueError(f"{label} is not a valid actor key: {actor!r}")


def derived_actor(runtime: str, branch: str, items: list[ActiveItem]) -> tuple[str, str]:
    matching = {
        item.writer
        for item in items
        if item.workspace == f"branch={branch}" and item.writer.startswith(f"{runtime}:")
    }
    if len(matching) == 1:
        return matching.pop(), "active-writer-workspace-match"
    if len(matching) > 1:
        raise ValueError("current branch maps to multiple runtime writers")
    if not branch:
        raise ValueError("detached HEAD has no derivable workline actor")
    workline = branch.split("/", 1)[1] if "/" in branch else branch
    workline = re.sub(r"[^A-Za-z0-9._/-]+", "-", workline).strip("-./")
    if not workline:
        raise ValueError("current branch does not yield a workline actor")
    return f"{runtime}:{workline}", "derived-from-current-branch"


def shared_surfaces(root: Path, config: dict, commit: str | None) -> list[str]:
    if not commit:
        return []
    git(root, "cat-file", "-e", f"{commit}^{{commit}}")
    changed = git(root, "diff-tree", "--no-commit-id", "--name-only", "-r", commit).splitlines()
    plan_dir = str(config.get("plan_dir") or "docs/plans").rstrip("/")
    history_paths = config.get("history_paths") or {}
    history_prefixes = {
        str(value).split("{", 1)[0].rsplit("/", 1)[0].rstrip("/") + "/"
        for value in history_paths.values()
        if isinstance(value, str) and "/" in value
    }
    result = []
    for path in changed:
        if (
            path in SHARED_EXACT
            or (plan_dir and path.startswith(f"{plan_dir}/"))
            or any(path.startswith(prefix) for prefix in history_prefixes)
        ):
            result.append(path)
    return sorted(set(result))


def parent_active_items(root: Path, commit: str, status_path: Path) -> list[ActiveItem]:
    relative_status = status_path.relative_to(root).as_posix()
    try:
        parent_text = git(root, "show", f"{commit}^:{relative_status}")
    except RuntimeError:
        return []
    return active_items(parent_text)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description="Resolve Project Log steward authority")
    result.add_argument("--root", required=True)
    result.add_argument("--runtime", required=True, choices=("claude", "codex"))
    authority = result.add_mutually_exclusive_group()
    authority.add_argument("--resume-actor")
    authority.add_argument("--as-human", dest="as_human")
    authority.add_argument("--confirmed-resume-actor")
    authority.add_argument("--confirmed-human")
    authority.add_argument("--confirmed-new-steward")
    result.add_argument("--commit")
    result.add_argument("--expected-head")
    return result


def main() -> int:
    args = parser().parse_args()
    root = Path(args.root).expanduser().resolve()
    try:
        confirmed = (
            args.confirmed_resume_actor
            or args.confirmed_human
            or args.confirmed_new_steward
        )
        if confirmed and not args.expected_head:
            return fail("prompt-bound confirmation requires --expected-head")
        if args.confirmed_new_steward and not args.commit:
            return fail("--confirmed-new-steward requires --commit")
        if not root.is_dir() or git(root, "rev-parse", "--show-toplevel") != str(root):
            return fail(f"not a repository root: {root}")
        config_path = root / ".doc-governance.json"
        if not config_path.is_file():
            print("authority-source: active-item-contract-not-enabled")
            print("verdict: NOT_APPLICABLE")
            return 0
        config = json.loads(config_path.read_text(encoding="utf-8"))
        if not active_contract(config):
            print("authority-source: active-item-contract-not-enabled")
            print("verdict: NOT_APPLICABLE")
            return 0
        status_path = root / str(config.get("status_schema", {}).get("path") or "STATUS.md")
        if not status_path.is_file():
            return fail(f"active-item contract enabled but status file missing: {status_path}")
        items = active_items(status_path.read_text(encoding="utf-8"))
        surfaces = shared_surfaces(root, config, args.commit)
        steward_source = "current-active-state"
        if not items and args.commit:
            items = parent_active_items(root, args.commit, status_path)
            if items:
                steward_source = "commit-parent-active-state"
        branch = git(root, "branch", "--show-current")
        head = git(root, "rev-parse", "HEAD")
        candidate = git(root, "rev-parse", f"{args.commit}^{{commit}}") if args.commit else None
        if args.expected_head:
            expected_head = git(root, "rev-parse", f"{args.expected_head}^{{commit}}")
            if args.expected_head != expected_head:
                return fail("--expected-head must be a full commit object ID")
            if expected_head != head:
                print(f"repository-head: {head}")
                print(f"expected-head: {expected_head}")
                print("authority-source: stale-prompt-snapshot")
                print("recovery-kind: none")
                print("verdict: STOP")
                return 1

        resume_actor = (
            args.resume_actor or args.confirmed_resume_actor or args.confirmed_new_steward
        )
        human_actor = args.as_human or args.confirmed_human
        if resume_actor:
            validate_actor(resume_actor, "resume actor")
            if not resume_actor.startswith(f"{args.runtime}:"):
                return fail("resume actor must use the same runtime prefix")
            if args.confirmed_new_steward:
                executor_source = "prompt-bound-new-workline-confirmation"
            elif args.confirmed_resume_actor:
                executor_source = "prompt-bound-same-runtime-resume"
            else:
                executor_source = "explicit-same-runtime-resume"
            executor = resume_actor
        else:
            executor, executor_source = derived_actor(args.runtime, branch, items)
        validate_actor(executor, "executor actor")

        stewards = sorted({item.steward for item in items})
        for steward in stewards:
            validate_actor(steward, "durable steward")
        if not stewards:
            if human_actor or resume_actor:
                print(f"executor-actor: {executor}")
                print(f"repository-head: {head}")
                print("durable-steward: none")
                print("durable-steward-source: none")
                print("authority-source: unverifiable-explicit-actor")
                print("recovery-kind: none")
                for path in surfaces:
                    print(f"candidate-shared-surface: {path}")
                if candidate:
                    print(f"candidate-commit: {candidate}")
                print("verdict: STOP")
                return 1
            if surfaces:
                print(f"executor-actor: {executor}")
                print(f"repository-head: {head}")
                print("durable-steward: none")
                print("durable-steward-source: none")
                print("authority-actor: none")
                print("authority-source: no-durable-steward-for-shared-surface")
                print("recovery-kind: confirm-create-active-contract")
                print(f"recovery-actor: {executor}")
                for path in surfaces:
                    print(f"candidate-shared-surface: {path}")
                if candidate:
                    print(f"candidate-commit: {candidate}")
                print("verdict: STOP")
                return 1
            print(f"executor-actor: {executor}")
            print(f"repository-head: {head}")
            print("durable-steward: none")
            print("durable-steward-source: none")
            print("authority-actor: none")
            print("authority-source: no-active-items")
            print("verdict: PASS")
            return 0
        if len(stewards) != 1:
            print(f"executor-actor: {executor}")
            print(f"repository-head: {head}")
            print(f"durable-steward: {','.join(stewards)}")
            print("authority-source: non-uniform-durable-state")
            print("recovery-kind: none")
            print("verdict: STOP")
            return 1

        steward = stewards[0]
        if human_actor:
            validate_actor(human_actor, "human delegation actor")
            if not human_actor.startswith(HUMAN_PREFIXES):
                return fail("--as-human accepts only human: or owner: steward actors")
            authority_actor = human_actor
            authority_source = (
                "prompt-bound-human-delegation"
                if args.confirmed_human
                else "explicit-bounded-human-delegation"
            )
        else:
            authority_actor = executor
            authority_source = executor_source

        print(f"executor-actor: {executor}")
        print(f"repository-head: {head}")
        print(f"durable-steward: {steward}")
        print(f"durable-steward-source: {steward_source}")
        print(f"authority-actor: {authority_actor}")
        print(f"authority-source: {authority_source}")
        for path in surfaces:
            print(f"candidate-shared-surface: {path}")
        if candidate:
            print(f"candidate-commit: {candidate}")

        if authority_actor != steward:
            if steward.startswith(HUMAN_PREFIXES):
                print("recovery-kind: confirm-human-delegation")
                print(f"recovery-actor: {steward}")
            elif steward.startswith(f"{args.runtime}:"):
                print("recovery-kind: confirm-same-runtime-resume")
                print(f"recovery-actor: {steward}")
            else:
                print("recovery-kind: none")
            print("verdict: STOP")
            return 1
        print("verdict: PASS")
        return 0
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        return fail(str(exc))


if __name__ == "__main__":
    sys.exit(main())
