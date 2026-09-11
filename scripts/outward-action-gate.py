#!/usr/bin/env python3
"""Classify push/merge shell commands and emit runtime-native hook decisions."""

from __future__ import annotations

import argparse
import json
import os
import shlex
import sys
from dataclasses import dataclass


SHELL_OPERATORS = {";", "&&", "||", "|", "&", "(", ")"}
SHELL_WRAPPERS = {"bash", "sh", "zsh"}


@dataclass(frozen=True)
class Finding:
    action: str
    canonical: bool

    def render(self) -> str:
        return f"{self.action} {'canonical' if self.canonical else 'opaque'}"


def shell_tokens(command: str) -> list[str]:
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()")
    lexer.whitespace_split = True
    lexer.commenters = "#"
    return list(lexer)


def split_commands(tokens: list[str]) -> list[list[str]]:
    commands: list[list[str]] = []
    current: list[str] = []
    for token in tokens:
        if token in SHELL_OPERATORS:
            if current:
                commands.append(current)
                current = []
        else:
            current.append(token)
    if current:
        commands.append(current)
    return commands


def strip_assignments(argv: list[str]) -> tuple[list[str], bool]:
    index = 0
    while index < len(argv):
        token = argv[index]
        name, separator, _ = token.partition("=")
        if not separator or not name or not name.replace("_", "a").isalnum() or name[0].isdigit():
            break
        index += 1
    return argv[index:], index > 0


def unwrap_prefix(argv: list[str]) -> tuple[list[str], bool]:
    argv, wrapped = strip_assignments(argv)
    while argv:
        executable = os.path.basename(argv[0])
        if executable in {"command", "exec"}:
            argv = argv[1:]
            wrapped = True
            continue
        if executable == "env":
            index = 1
            while index < len(argv) and (argv[index].startswith("-") or "=" in argv[index]):
                index += 1
            argv = argv[index:]
            wrapped = True
            continue
        if executable == "sudo":
            index = 1
            while index < len(argv) and argv[index].startswith("-"):
                index += 1
            argv = argv[index:]
            wrapped = True
            continue
        break
    return argv, wrapped


def git_subcommand(argv: list[str]) -> tuple[str | None, bool, list[str]]:
    index = 1
    used_global_options = False
    takes_value = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}
    while index < len(argv):
        token = argv[index]
        if not token.startswith("-"):
            return token, used_global_options, argv[index + 1 :]
        used_global_options = True
        if token in takes_value:
            index += 2
        else:
            index += 1
    return None, used_global_options, []


def classify_argv(argv: list[str], *, inherited_wrapper: bool = False) -> Finding | None:
    argv, prefix_wrapper = unwrap_prefix(argv)
    if not argv:
        return None

    executable = os.path.basename(argv[0])
    wrapped = inherited_wrapper or prefix_wrapper or argv[0] != executable

    if executable in SHELL_WRAPPERS:
        for index, token in enumerate(argv[1:], start=1):
            if token.startswith("-") and "c" in token[1:] and index + 1 < len(argv):
                nested = classify(argv[index + 1])
                return Finding(nested.action, False) if nested else None
        return None

    if executable == "xargs":
        index = 1
        while index < len(argv) and argv[index].startswith("-"):
            index += 1
        return classify_argv(argv[index:], inherited_wrapper=True)

    if executable == "git":
        subcommand, global_options, remainder = git_subcommand(argv)
        if subcommand not in {"push", "send-pack"}:
            return None
        if "--dry-run" in remainder or "-n" in remainder:
            return None
        return Finding("push", not (wrapped or global_options))

    if executable == "gh" and len(argv) >= 3 and argv[1:3] == ["pr", "merge"]:
        return Finding("merge", not wrapped)

    return None


def classify(command: str) -> Finding | None:
    try:
        tokens = shell_tokens(command)
    except ValueError:
        return None
    commands = split_commands(tokens)
    findings = [finding for argv in commands if (finding := classify_argv(argv))]
    if not findings:
        return None
    first = findings[0]
    if len(commands) != 1 or len(findings) != 1:
        return Finding(first.action, False)
    return first


def hook_response(runtime: str, finding: Finding) -> dict[str, object] | None:
    if runtime == "codex" and finding.canonical:
        return None

    decision = "ask" if runtime == "claude" else "deny"
    if runtime == "claude":
        reason = f"{finding.action} publishes or merges remote state and requires current user approval."
    else:
        reason = (
            f"Opaque {finding.action} command blocked. Re-run it as a direct canonical command "
            "so the Codex exec policy can display its approval prompt."
        )
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
        }
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--classify", metavar="COMMAND")
    mode.add_argument("--runtime", choices=("claude", "codex"))
    args = parser.parse_args()

    if args.classify is not None:
        finding = classify(args.classify)
        print(finding.render() if finding else "none")
        return 0

    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return 0
    if payload.get("tool_name") != "Bash":
        return 0
    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict) or not isinstance(tool_input.get("command"), str):
        return 0

    finding = classify(tool_input["command"])
    if finding is None:
        return 0
    response = hook_response(args.runtime, finding)
    if response is not None:
        json.dump(response, sys.stdout, separators=(",", ":"))
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
