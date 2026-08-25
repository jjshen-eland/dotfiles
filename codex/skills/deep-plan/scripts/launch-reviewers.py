#!/usr/bin/env python3
"""Launch fresh Codex plan reviewers without writing orchestration artifacts."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import stat
import subprocess
import sys
import time


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", required=True)
    parser.add_argument("--repo", action="append", required=True)
    parser.add_argument("--brief", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--count", type=int, default=2)
    parser.add_argument("--criteria-impact-review", action="store_true")
    parser.add_argument("--timeout-seconds", type=int, default=900)
    parser.add_argument("--codex-bin", default="codex")
    return parser.parse_args()


def checked_path(raw: str, kind: str, want_dir: bool) -> Path:
    if any(not char.isprintable() for char in raw):
        raise ValueError(f"{kind} path contains a forbidden control character")
    expanded = Path(raw).expanduser()
    if not expanded.is_absolute():
        raise ValueError(f"{kind} path must be absolute")
    path = expanded.resolve(strict=True)
    if any(not char.isprintable() for char in str(path)):
        raise ValueError(f"resolved {kind} path contains a forbidden control character")
    if want_dir != path.is_dir():
        expected = "directory" if want_dir else "file"
        raise ValueError(f"{kind} is not a {expected}: {path}")
    return path


def run_git(repo: Path, *args: str) -> str:
    completed = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    return completed.stdout


def run_git_bytes(repo: Path, *args: str) -> bytes:
    completed = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return completed.stdout


def repo_content_sha256(repo: Path) -> str:
    """Fingerprint the index plus every tracked or untracked, non-ignored worktree file."""
    digest = hashlib.sha256()
    index_listing = run_git_bytes(repo, "ls-files", "--stage", "-z")
    digest.update(b"index\0")
    digest.update(index_listing)
    worktree_paths = run_git_bytes(
        repo, "ls-files", "--cached", "--others", "--exclude-standard", "-z"
    ).split(b"\0")
    repo_bytes = os.fsencode(repo)
    for relative_path in sorted(path for path in worktree_paths if path):
        absolute_path = os.path.join(repo_bytes, relative_path)
        digest.update(b"path\0")
        digest.update(len(relative_path).to_bytes(8, "big"))
        digest.update(relative_path)
        try:
            metadata = os.lstat(absolute_path)
        except FileNotFoundError:
            digest.update(b"missing\0")
            continue
        digest.update(stat.S_IFMT(metadata.st_mode).to_bytes(4, "big"))
        digest.update(stat.S_IMODE(metadata.st_mode).to_bytes(4, "big"))
        if stat.S_ISLNK(metadata.st_mode):
            target = os.readlink(absolute_path)
            target_bytes = target if isinstance(target, bytes) else os.fsencode(target)
            digest.update(b"symlink\0")
            digest.update(len(target_bytes).to_bytes(8, "big"))
            digest.update(target_bytes)
        elif stat.S_ISREG(metadata.st_mode):
            digest.update(b"file\0")
            digest.update(metadata.st_size.to_bytes(8, "big"))
            with open(absolute_path, "rb") as handle:
                while chunk := handle.read(1024 * 1024):
                    digest.update(chunk)
        else:
            digest.update(b"special\0")
    return digest.hexdigest()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def reviewer_prompt(
    plan: Path,
    repos: list[Path],
    brief: Path,
    template: Path,
    criteria_prompt: Path,
    criteria_impact_review: bool,
) -> str:
    repo_lines = "\n".join(f"  {repo}" for repo in repos)
    criteria_paragraph = (
        criteria_prompt.read_text(encoding="utf-8").strip()
        if criteria_impact_review
        else ""
    )
    prompt = template.read_text(encoding="utf-8")
    replacements = {
        "{PLAN_ABSOLUTE_PATH}": str(plan),
        "{REPO_ABSOLUTE_PATHS}": repo_lines,
        "{BRIEF_ABSOLUTE_PATH}": str(brief),
        "{CRITERIA_IMPACT_PARAGRAPH}": criteria_paragraph,
    }
    for token, replacement in replacements.items():
        if prompt.count(token) != 1:
            raise ValueError(f"shared reviewer prompt must contain exactly one {token}")
        prompt = prompt.replace(token, replacement)
    return prompt


def valid_review(value: object) -> bool:
    if not isinstance(value, dict) or set(value) != {
        "findings",
        "verified_claims",
        "unverified_claims",
        "recommendation",
    }:
        return False
    if value["recommendation"] not in {"start", "do_not_start"}:
        return False
    list_keys = ("findings", "verified_claims", "unverified_claims")
    if not all(isinstance(value[key], list) for key in list_keys):
        return False
    if not all(
        isinstance(item, str)
        for key in ("verified_claims", "unverified_claims")
        for item in value[key]
    ):
        return False
    for finding in value["findings"]:
        if not isinstance(finding, dict) or set(finding) != {
            "issue",
            "layer",
            "severity",
            "evidence",
        }:
            return False
        if finding["layer"] not in {"verifiable", "judgment"}:
            return False
        if finding["severity"] not in {"blocker", "high", "medium", "low"}:
            return False
        if not isinstance(finding["issue"], str) or not finding["issue"]:
            return False
        if not isinstance(finding["evidence"], list) or not finding["evidence"]:
            return False
        if not all(isinstance(item, str) and item for item in finding["evidence"]):
            return False
    return True


def parse_event(raw_line: bytes) -> tuple[str | None, object | None]:
    try:
        event = json.loads(raw_line)
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None, None
    if event.get("type") == "thread.started":
        thread_id = event.get("thread_id")
        return (thread_id if isinstance(thread_id, str) and thread_id else None), None
    if event.get("type") != "item.completed":
        return None, None
    item = event.get("item")
    if not isinstance(item, dict) or item.get("type") != "agent_message":
        return None, None
    text = item.get("text")
    if not isinstance(text, str):
        return None, None
    try:
        review = json.loads(text)
    except json.JSONDecodeError:
        return None, None
    return None, review if valid_review(review) else None


def main() -> int:
    args = parse_args()
    guard_name = "DEEP_PLAN_REVIEWER_PROCESS"
    if os.environ.get(guard_name):
        raise RuntimeError("nested deep-plan reviewer launch is forbidden")
    if not 2 <= args.count <= 8:
        raise ValueError("--count must be between 2 and 8")
    if args.timeout_seconds < 1:
        raise ValueError("--timeout-seconds must be positive")

    plan = checked_path(args.plan, "plan", want_dir=False)
    brief = checked_path(args.brief, "brief", want_dir=False)
    schema = checked_path(args.schema, "schema", want_dir=False)
    repos = list(
        dict.fromkeys(checked_path(value, "repo", want_dir=True) for value in args.repo)
    )
    if not repos:
        raise ValueError("at least one repository is required")
    skill_dir = Path(__file__).resolve().parent.parent
    expected_brief = (skill_dir / "references" / "planner-brief.md").resolve(strict=True)
    prompt_template = (skill_dir / "references" / "reviewer-prompt.txt").resolve(
        strict=True
    )
    criteria_prompt = (
        skill_dir / "references" / "criteria-impact-prompt.txt"
    ).resolve(strict=True)
    expected_schema = (skill_dir / "assets" / "reviewer-output.schema.json").resolve(strict=True)
    if brief != expected_brief:
        raise ValueError("brief must be this skill's shared reviewer contract")
    if schema != expected_schema:
        raise ValueError("schema must be this skill's reviewer output schema")

    codex_bin = shutil.which(args.codex_bin)
    if codex_bin is None:
        raise ValueError(f"Codex executable not found: {args.codex_bin}")

    repo_state_before = []
    for repo in repos:
        top = Path(run_git(repo, "rev-parse", "--show-toplevel").strip()).resolve()
        if top != repo:
            raise ValueError(f"repo must be its git toplevel: {repo}")
        repo_state_before.append(
            {
                "path": str(repo),
                "head": run_git(repo, "rev-parse", "HEAD").strip(),
                "status": run_git(repo, "status", "--porcelain=v1", "-uall"),
                "content_sha256": repo_content_sha256(repo),
            }
        )

    prompt = reviewer_prompt(
        plan,
        repos,
        brief,
        prompt_template,
        criteria_prompt,
        args.criteria_impact_review,
    )
    prompt_bytes = prompt.encode("utf-8")
    prompt_sha = sha256_bytes(prompt_bytes)
    plan_sha = sha256_bytes(plan.read_bytes())
    manifest: dict[str, object] = {
        "version": 2,
        "ok": False,
        "plan": str(plan),
        "plan_sha256": plan_sha,
        "brief_sha256": sha256_bytes(brief.read_bytes()),
        "prompt_template_sha256": sha256_bytes(prompt_template.read_bytes()),
        "criteria_prompt_sha256": sha256_bytes(criteria_prompt.read_bytes()),
        "schema_sha256": sha256_bytes(schema.read_bytes()),
        "prompt_sha256": prompt_sha,
        "requested_reviewers": args.count,
        "criteria_impact_review": args.criteria_impact_review,
        "repos_before": repo_state_before,
        "reviewers": [],
        "child_contract": {
            "sandbox": "read-only",
            "ephemeral": True,
            "multi_agent": False,
            "skill_search": False,
            "hooks": False,
            "plugins": False,
            "structured_output": True,
            "orchestration_files_written": False,
            "process_tree_cleanup": (
                "process-group"
                if os.name == "posix"
                else "taskkill-tree"
                if os.name == "nt"
                else "direct-process"
            ),
        },
    }

    processes: list[dict[str, object]] = []

    def signal_process_tree(process: subprocess.Popen[bytes], force: bool) -> None:
        if os.name == "posix":
            chosen_signal = signal.SIGKILL if force else signal.SIGTERM
            try:
                os.killpg(process.pid, chosen_signal)
            except ProcessLookupError:
                pass
            return
        if os.name == "nt":
            subprocess.run(
                ["taskkill", "/PID", str(process.pid), "/T", "/F"],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return
        if process.poll() is None:
            (process.kill if force else process.terminate)()

    def terminate_children(_signum: int | None = None, _frame: object | None = None) -> None:
        for entry in processes:
            process = entry["process"]
            signal_process_tree(process, force=False)  # type: ignore[arg-type]
        cleanup_deadline = time.monotonic() + 5
        for entry in processes:
            process = entry["process"]
            try:
                process.wait(  # type: ignore[union-attr]
                    timeout=max(0, cleanup_deadline - time.monotonic())
                )
            except subprocess.TimeoutExpired:
                pass
        for entry in processes:
            process = entry["process"]
            signal_process_tree(process, force=True)  # type: ignore[arg-type]
            process.wait()  # type: ignore[union-attr]
        if _signum is not None:
            raise KeyboardInterrupt

    handled_signals = [signal.SIGINT, signal.SIGTERM]
    for signal_name in ("SIGHUP", "SIGQUIT"):
        if hasattr(signal, signal_name):
            handled_signals.append(getattr(signal, signal_name))
    previous_handlers = {
        handled_signal: signal.signal(handled_signal, terminate_children)
        for handled_signal in handled_signals
    }
    try:
        child_env = os.environ.copy()
        child_env[guard_name] = "1"
        command = [
            codex_bin,
            "exec",
            "-C",
            str(repos[0]),
            "-s",
            "read-only",
            "--ephemeral",
            "--ignore-user-config",
            "--ignore-rules",
            "--disable",
            "multi_agent",
            "--disable",
            "skill_search",
            "--disable",
            "hooks",
            "--disable",
            "plugins",
            "--json",
            "--output-schema",
            str(schema),
            "-",
        ]
        for index in range(args.count):
            process = subprocess.Popen(
                command,
                cwd=repos[0],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                env=child_env,
                start_new_session=os.name == "posix",
            )
            processes.append(
                {
                    "label": chr(ord("A") + index),
                    "process": process,
                    "pid": process.pid,
                    "started_ns": time.time_ns(),
                }
            )

        all_running = all(
            entry["process"].poll() is None for entry in processes  # type: ignore[union-attr]
        )
        manifest["all_running_after_dispatch"] = all_running
        manifest["dispatch_completed_ns"] = time.time_ns()
        if not all_running:
            raise RuntimeError("a reviewer exited before all reviewers were dispatched")

        for entry in processes:
            process = entry["process"]
            process.stdin.write(prompt_bytes)  # type: ignore[union-attr]
            process.stdin.close()  # type: ignore[union-attr]

        def collect(entry: dict[str, object]) -> dict[str, object]:
            process = entry["process"]
            digest = hashlib.sha256()
            event_bytes = 0
            output_tail = b""
            thread_id = None
            review = None
            for raw_line in process.stdout:  # type: ignore[union-attr]
                digest.update(raw_line)
                event_bytes += len(raw_line)
                output_tail = (output_tail + raw_line)[-500:]
                event_thread_id, event_review = parse_event(raw_line)
                if event_thread_id is not None:
                    thread_id = event_thread_id
                if event_review is not None:
                    review = event_review
            exit_code = process.wait()  # type: ignore[union-attr]
            record = {
                "label": entry["label"],
                "pid": entry["pid"],
                "started_ns": entry["started_ns"],
                "completed_ns": time.time_ns(),
                "exit_code": exit_code,
                "thread_id": thread_id,
                "prompt_sha256": prompt_sha,
                "events_sha256": digest.hexdigest(),
                "event_bytes": event_bytes,
                "review": review,
            }
            if exit_code != 0:
                record["output_tail"] = output_tail.decode("utf-8", errors="replace")
            return record

        reviewer_records = []
        pool = ThreadPoolExecutor(max_workers=args.count)
        try:
            futures = [pool.submit(collect, entry) for entry in processes]
            for future in as_completed(futures, timeout=args.timeout_seconds):
                reviewer_records.append(future.result())
        finally:
            pool.shutdown(wait=False, cancel_futures=True)
        reviewer_records.sort(key=lambda record: record["label"])
        manifest["reviewers"] = reviewer_records

        repo_state_after = []
        for repo in repos:
            repo_state_after.append(
                {
                    "path": str(repo),
                    "head": run_git(repo, "rev-parse", "HEAD").strip(),
                    "status": run_git(repo, "status", "--porcelain=v1", "-uall"),
                    "content_sha256": repo_content_sha256(repo),
                }
            )
        manifest["repos_after"] = repo_state_after
        manifest["plan_sha256_after"] = sha256_bytes(plan.read_bytes())
        manifest["brief_sha256_after"] = sha256_bytes(brief.read_bytes())
        manifest["prompt_template_sha256_after"] = sha256_bytes(
            prompt_template.read_bytes()
        )
        manifest["criteria_prompt_sha256_after"] = sha256_bytes(
            criteria_prompt.read_bytes()
        )
        manifest["schema_sha256_after"] = sha256_bytes(schema.read_bytes())

        thread_ids = [record["thread_id"] for record in reviewer_records]
        manifest["ok"] = (
            len(reviewer_records) == args.count
            and all(record["exit_code"] == 0 for record in reviewer_records)
            and all(valid_review(record["review"]) for record in reviewer_records)
            and all(isinstance(value, str) and value for value in thread_ids)
            and len(set(thread_ids)) == args.count
            and all(record["prompt_sha256"] == prompt_sha for record in reviewer_records)
            and repo_state_after == repo_state_before
            and manifest["plan_sha256_after"] == plan_sha
            and manifest["brief_sha256_after"] == manifest["brief_sha256"]
            and manifest["prompt_template_sha256_after"]
            == manifest["prompt_template_sha256"]
            and manifest["criteria_prompt_sha256_after"]
            == manifest["criteria_prompt_sha256"]
            and manifest["schema_sha256_after"] == manifest["schema_sha256"]
        )
    except BaseException as exc:
        manifest["error"] = f"{type(exc).__name__}: {exc}"
        terminate_children()
    finally:
        for handled_signal, previous_handler in previous_handlers.items():
            signal.signal(handled_signal, previous_handler)

    print(json.dumps(manifest, ensure_ascii=False, separators=(",", ":")))
    return 0 if manifest["ok"] else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(json.dumps({"ok": False, "error": f"{type(exc).__name__}: {exc}"}))
        sys.exit(2)
