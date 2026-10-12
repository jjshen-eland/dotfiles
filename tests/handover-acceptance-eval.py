# -*- coding: utf-8 -*-
"""Opt-in native eval for Project transfer handover acceptance (pressure-tests Scenario 42).

Running `transfer` and `answer` consumes the authenticated account's model usage.

usage: handover-acceptance-eval.py setup <root> <source>  # fixture repo + local origin; skill entry from <source>
       handover-acceptance-eval.py transfer <root>         # Sonnet runs /project transfer as the giver
       handover-acceptance-eval.py publish <root>          # stand-in for Log: commit the guide, push to main
       handover-acceptance-eval.py answer <root> <arm>     # fresh clone + fresh agent answers
                                                           # arm: full | no-deploy | no-private (negative control)
       handover-acceptance-eval.py grade <root> <arm>

<source> is a directory holding claude/skills/project and shared/skills/project (e.g. a git archive).
"""
import json
import os
import pathlib
import shutil
import subprocess
import sys

MODEL = "claude-sonnet-5-5"
GRADER = pathlib.Path(__file__).resolve().parent.parent / "shared/skills/project/scripts/grade-handover.py"
ENV = dict(os.environ, GIT_AUTHOR_DATE="2026-10-12T00:00:00Z", GIT_COMMITTER_DATE="2026-10-12T00:00:00Z")


def git(w, *a):
    return subprocess.run(["git", *a], cwd=w, capture_output=True, text=True, check=True, env=ENV).stdout


def write(w, rel, text):
    p = w / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)


def setup(root, source):
    root.mkdir(parents=True)
    w = root / "work"
    w.mkdir()
    git(w, "init", "-q", "-b", "main")
    git(w, "config", "user.name", "Giver")
    git(w, "config", "user.email", "giver@example.invalid")
    write(w, "README.md", "# kb-sync\n\nNightly sync of the upstream filings API into the local store.\n\n"
          "## Setup\n\n1. `cp .env.example .env` and fill in the values.\n2. Run `./tests/run.sh`.\n")
    write(w, "AGENTS.md", "# Contract\n\nNever commit on main; stage explicit paths. The complete test command is "
          "`./tests/run.sh`. Decisions and dead ends live in `docs/decisions.md`; active work in `STATUS.md`.\n")
    write(w, "CLAUDE.md", "@AGENTS.md\n")
    write(w, ".gitignore", ".env\ntmp/\n")
    write(w, ".env.example", "SYNC_API_TOKEN=\nSTORE_DSN=\n")
    write(w, ".env", "SYNC_API_TOKEN=fixture-secret-token\nSTORE_DSN=postgres://fixture-only\n")
    write(w, "app/sync.py", "def window():\n    return '02:00'\n")
    write(w, "tests/test_sync.py", "import sys\nfrom pathlib import Path\n"
          "sys.path.insert(0, str(Path(__file__).resolve().parents[1]))\n"
          "from app.sync import window\nassert window() == '02:00'\nprint('1 passed')\n")
    write(w, "tests/run.sh", "#!/bin/sh\nset -eu\ncd \"$(dirname \"$0\")/..\"\n"
          f"exec '{sys.executable}' -B tests/test_sync.py\n")
    (w / "tests/run.sh").chmod(0o755)
    write(w, "deploy/crontab", "0 2 * * * cd /srv/kb-sync && ./bin/sync >> /var/log/kb-sync.log 2>&1\n")
    write(w, "docs/decisions.md", "# Decisions\n\n"
          "- **D-20261001-nightly-sync-window**: run the sync at 02:00 because the upstream API is in maintenance "
          "from 00:30 to 01:30.\n"
          "- **X-20261003-realtime-webhook**: dead end. The upstream webhook drops events under load, so realtime "
          "sync was abandoned in favour of the nightly batch.\n")
    write(w, "STATUS.md", "# STATUS\n\n## 進行中\n\n### 1. Retry with backoff\n\n"
          "- **Goal**: failed upstream calls retry three times with exponential backoff.\n"
          "- **進度**: implementation started on branch feat/retry-backoff.\n"
          "- **下一步**: finish tests on feat/retry-backoff.\n\n## 暫停中\n\n目前無暫停項目。\n")
    git(w, "add", "README.md", "AGENTS.md", "CLAUDE.md", ".gitignore", ".env.example", "app/sync.py",
        "tests/test_sync.py", "tests/run.sh", "deploy/crontab", "docs/decisions.md", "STATUS.md")
    git(w, "commit", "-qm", "feat: nightly sync")
    git(w, "switch", "-qc", "feat/retry-backoff")
    write(w, "app/retry.py", "def attempts():\n    return 3\n")
    git(w, "add", "app/retry.py")
    git(w, "commit", "-qm", "feat: start retry with backoff")
    git(w, "switch", "-q", "main")
    git(w, "switch", "-qc", "docs/handover")
    git(w, "init", "--bare", "-q", str(root / "origin.git"))
    git(w, "remote", "add", "origin", str(root / "origin.git"))
    git(w, "push", "-q", "origin", "main", "feat/retry-backoff")
    skills = w / ".claude/skills"
    skills.mkdir(parents=True)
    (skills / "project").symlink_to(source / "claude/skills/project", target_is_directory=True)
    (w / ".git/info/exclude").write_text(".claude/\n")
    print(root)


def claude(cwd, prompt, out, tools="Bash,Read,Glob,Grep,Edit,Write"):
    cmd = ["claude", "-p", prompt, "--model", MODEL, "--effort", "high", "--setting-sources", "",
           "--settings", '{"disableAllHooks":true}', "--strict-mcp-config", "--tools", tools,
           "--allowedTools", tools, "--permission-mode", "acceptEdits", "--output-format", "stream-json", "--verbose"]
    with open(out, "w") as fh:
        rc = subprocess.run(cmd, cwd=cwd, stdout=fh, stderr=subprocess.STDOUT).returncode
    print("claude rc", rc, out)


def transfer(root):
    w = root / "work"
    prompt = ("/project transfer . to=human:alice\n\n我要把 kb-sync 移交給新同事 alice。以下是只有我知道、repo 裡沒寫的事："
              "同步程式跑在主機 ops01（排程設定就是 repo 的 deploy/crontab），log 在 /var/log/kb-sync.log，掛掉時先看這個 log；"
              "SYNC_API_TOKEN 與 STORE_DSN 的值放在 1Password 的 kb-ops vault，由平台組 Bob 核發；"
              "我可以支援到 2026-11-30，透過 Slack #kb-ops 找我。請使用本 fixture 的 .claude/skills/project/SKILL.md 作為入口。")
    claude(w, prompt, root / "transfer.jsonl")


def publish(root):
    w = root / "work"
    status = git(w, "status", "--porcelain", "--untracked-files=all")
    print(status)
    tracked_ok = git(w, "ls-files", "tmp/transfer-acceptance.json").strip() == ""
    ignored = subprocess.run(["git", "check-ignore", "-q", "tmp/transfer-acceptance.json"], cwd=w).returncode == 0
    print("acceptance untracked", tracked_ok, "ignored", ignored, "exists", (w / "tmp/transfer-acceptance.json").exists())
    changed = [line[3:] for line in status.splitlines() if not line[3:].startswith("tmp/")]
    git(w, "add", *changed)
    git(w, "commit", "-qm", "docs: add handover guide")
    git(w, "push", "-q", "origin", "HEAD:main")


def answer(root, arm):
    clone = root / f"clone-{arm}"
    if clone.exists():
        shutil.rmtree(clone)
    subprocess.run(["git", "clone", "-q", str(root / "origin.git"), str(clone)], check=True)
    guide = clone / "docs/transfer.md"
    if arm == "no-deploy":
        lines = guide.read_text().split("\n")
        start = next(i for i, l in enumerate(lines) if l.startswith("## 3."))
        end = next(i for i in range(start + 1, len(lines)) if lines[i].startswith("## "))
        guide.write_text("\n".join(lines[:start] + lines[end:]))
    if arm == "no-private":
        keep = [l for l in guide.read_text().split("\n") if not any(t in l for t in ("ops01", "1Password", "kb-ops"))]
        guide.write_text("\n".join(keep))
    # Hand the answerer a history-free snapshot: an edited guide must not be recoverable via git diff/log.
    shutil.rmtree(clone / ".git")
    for args in (("init", "-q", "-b", "main"), ("config", "user.name", "Snapshot"),
                 ("config", "user.email", "snapshot@example.invalid"), ("add", "-A"),
                 ("commit", "-qm", "snapshot")):
        git(clone, *args)
    out = root / f"answers-{arm}.json"
    prompt = (f"你是剛接手這個 repo 的工程師 alice，前任已離開、無法詢問。只能使用目前目錄這個 repo 的內容。"
              f"請回答 docs/transfer.md「接手驗收題組」的每一題，依該節說明的格式，把答案 JSON 寫到 {out}。"
              f"不要讀取目前目錄以外的任何檔案。")
    claude(clone, prompt, root / f"answer-{arm}.jsonl")


def grade(root, arm):
    r = subprocess.run([sys.executable, "-B", str(GRADER), "--spec", str(root / "work/tmp/transfer-acceptance.json"),
                        "--answers", str(root / f"answers-{arm}.json"), "--clone", str(root / f"clone-{arm}"),
                        # The fixture's only command question is its local test runner; inspect the listed
                        # command in the transcript before trusting a PASS.
                        "--allow-exec"],
                       capture_output=True, text=True)
    print(r.stdout + r.stderr)
    print("grader rc", r.returncode)


action, root = sys.argv[1], pathlib.Path(sys.argv[2])
if action == "setup":
    setup(root, pathlib.Path(sys.argv[3]))
elif action == "transfer":
    transfer(root)
elif action == "publish":
    publish(root)
elif action == "answer":
    answer(root, sys.argv[3])
elif action == "grade":
    grade(root, sys.argv[3])
