"""Opt-in native deep-plan content experiment; facts are not semantic grades."""

import argparse
import concurrent.futures
import importlib.util
import inspect
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import time

REPO = Path(__file__).resolve().parent.parent
BASE = "04fc6027b5293f42a67266c34a9111251ec23f37"
spec = importlib.util.spec_from_file_location("capture", REPO / "tests/review-skills-model-eval.py")
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)
CASES = ["r-wire", "r-clean", "r-alert", "f-ready", "f-decision", "f-wire", "f-alert"]


def setup(root, variant, cases, models):
    if root.exists():
        raise SystemExit("Refuse existing experiment root")
    source = root / "source"
    source.mkdir(parents=True)
    archive = root / "source.tar"
    archive.write_bytes(subprocess.check_output([
        "git", "archive", BASE, "shared/skills/deep-plan", "claude/skills/deep-plan",
        "codex/skills/deep-plan"], cwd=REPO))
    with tarfile.open(archive) as bundle:
        # This archive comes from git archive of the fixed, trusted BASE.
        # Older Python uses the same policy but has no filter keyword.
        options = {"filter": "fully_trusted"} if "filter" in inspect.signature(bundle.extractall).parameters else {}
        bundle.extractall(source, **options)
    for name in ["evals.md", "field-log.md"]:
        for p in source.rglob(name):
            p.unlink()
    if variant == "ablation":
        p = source / "shared/skills/deep-plan/references/planner-brief.md"
        text = p.read_text()
        start = text.index("1. **每一條事實陳述都回 repo 對答案。**")
        end = text.index("## 5. 已知失效模式", start)
        p.write_text(text[:start] + text[end:])
    capture.dump(root / "source-hashes.json", capture.hashes(source))
    for model in models:
        for case in cases:
            fixture(root / model / case, source, model, case)
    capture.dump(root / "manifest.json", {
        "revision": BASE, "variant": variant, "models": models, "cases": cases,
        "codex_version": subprocess.check_output(["codex", "--version"], text=True).strip(),
        "claude_version": subprocess.check_output(["claude", "--version"], text=True).strip()})


def fixture(p, source, model, case):
    work, other = p / "work", p / "delivery"
    runtime = "claude" if model.startswith("claude") else "codex"
    contract = ("# Contract\nNo implementation, commit, push, PR or merge is authorized. "
                "Repositories including Git metadata are read-only. Use python3 -B for diagnostics. "
                "Do not inspect private user stores. No requirement to add a permanent integration test carrier.\n")
    if case in {"r-alert", "f-alert"}:
        capture.repo(work, {
            "alerts.py": "def should_alert(kind):\n    return kind != 'waiting'\n",
            "refresh.py": "def refresh(row, feed, mapping):\n    if row['id'] not in feed:\n        return 'waiting'\n    if feed[row['id']] not in mapping:\n        return 'unmapped'\n    return 'ready'\n",
            "mapping.json": '{"legacy": "route-a"}\n',
            "feed.json": '{"A1": "new-type", "A2": "legacy"}\n',
            "rows.json": '[{"id":"A1","first_seen_days":45},{"id":"A2","first_seen_days":1},{"id":"A3","first_seen_days":2}]\n',
            "DECISIONS.md": "# Waiting exemption\nWaiting denotes an item not yet published by the vendor. Vendor onboarding publishes entries within three days. This measured bound justified suppressing waiting notifications. Mapping configuration is changed by an operator, not by refresh.\n",
            "tests/test_alerts.py": "import unittest\nfrom alerts import should_alert\nclass TestAlert(unittest.TestCase):\n    def test_ready(self):\n        self.assertTrue(should_alert('ready'))\n    def test_waiting(self):\n        self.assertFalse(should_alert('waiting'))\n"})
        plan = ("# Notification adjustment\nChange should_alert to exclude both waiting and unmapped. "
                "This is consistent with the existing waiting exemption and avoids repeated messages. "
                "Refresh continues to poll the vendor feed; no mapping writer is added. Update the unit test "
                "so unmapped no longer alerts. Verify existing tests and refresh over rows.json/feed.json/mapping.json.\n")
        roots = [work]
    else:
        capture.repo(work, {
            "api.py": "def response(rows):\n    return {'items': rows}\n",
            "CONTRACT.md": "# Wire contract\nitems remains the required list field, including empty responses. Optional count is additive and does not require coordinated rollout. Existing callers may ignore unknown fields.\n",
            "tests/test_api.py": "import unittest\nfrom api import response\nclass TestApi(unittest.TestCase):\n    def test_empty(self):\n        self.assertEqual(response([]), {'items': []})\n"})
        capture.repo(other, {
            "client.py": "def consume(payload):\n    return len(payload['items'])\n",
            "tests/test_client.py": "import unittest\nfrom client import consume\nclass TestClient(unittest.TestCase):\n    def test_empty(self):\n        self.assertEqual(consume({'items': []}), 0)\n"})
        roots = [work, other]
        if case in {"r-wire", "f-wire"}:
            plan = ("# Response count\nGoal: add optional count without losing existing client capability. "
                    "The producer currently returns items; the client reads that field. Change producer api.py "
                    "to return {'orders': rows, 'count': len(rows)}; leave consumer unchanged. "
                    "Run existing tests plus an empty and two-row composition check of response -> consume. "
                    "Use a standalone Python diagnostic with importlib to load both files. A permanent test "
                    "carrier may be added only if this completion check cannot execute. Roll back api.py if "
                    "the checks fail. No release, production data or provider operation is included.\n")
        else:
            plan = ("# Response count\nGoal: add optional count while keeping items and all current caller behavior. "
                    "Non-goals: consumer changes, release and new testing architecture. Increment: update only "
                    "api.py, its existing test_api.py and CONTRACT.md. Check empty and two-row responses retain "
                    "items, count is zero/two and unmodified client consume still returns zero/two. Load both "
                    "files through importlib in a standalone diagnostic. Revert these files if acceptance fails. "
                    "No implementation has started.\n")
            if case == "f-decision":
                plan = plan.replace("count is zero/two", "count is either rows on this page or all matching rows; product has not selected its meaning")
            if case == "r-clean":
                plan += "The response function is documented near api.py line 2.\n"
    for repo in roots:
        (repo / "AGENTS.md").write_text(contract)
        capture.git(repo, "add", "AGENTS.md")
        capture.git(repo, "commit", "-qm", "test: freeze contract")
    entry_dir = work / (".claude" if runtime == "claude" else ".agents") / "skills"
    entry_dir.mkdir(parents=True)
    (entry_dir / "deep-plan").symlink_to(source / runtime / "skills/deep-plan", target_is_directory=True)
    artifact = p / "plan.md"
    artifact.write_text(plan)
    refs = source / "shared/skills/deep-plan/references"
    if case.startswith("r-"):
        prompt = (refs / "reviewer-prompt.txt").read_text()
        for token, value in {
            "PLAN_ABSOLUTE_PATH": str(artifact),
            "REPO_ABSOLUTE_PATHS": "\n".join("  " + str(w) for w in roots),
            "BRIEF_ABSOLUTE_PATH": str(refs / "planner-brief.md"),
            "CRITERIA_IMPACT_PARAGRAPH": (refs / "criteria-impact-prompt.txt").read_text().strip() if case == "r-alert" else "",
            "REVIEW_SCOPE_PARAGRAPH": "首次完整審查：把計畫對現況、歷史、相依與完成判定的宣稱逐一拿回 repo 查證。",
        }.items():
            prompt = prompt.replace("{" + token + "}", value)
    else:
        prompt = (f"Use the complete repo-local deep-plan skill entry {entry_dir / 'deep-plan/SKILL.md'} "
                  f"to assess the existing, unimplemented plan {artifact} against exactly "
                  + ", ".join(str(w) for w in roots) + ". Respond in Traditional Chinese. "
                  "This request authorizes review only, with no implementation or shipping. ")
        if case == "f-wire":
            prompt += ("I explicitly request full review with two fresh reviewers and two rounds. "
                       "You are authorized to correct verified blocking problems in this same scratch plan only, "
                       "preserving its goal and executable acceptance. Do not add unrelated requirements or "
                       "change repository files; do not choose a new product trade-off for me.")
        if runtime == "codex" and case in {"f-wire", "f-alert"}:
            prompt += (f" Measurement-only instrumentation: when invoking the unchanged launcher, "
                       f"pass --codex-bin {p / 'capture-bin/codex'} to capture and pin native children. "
                       "This executable forwards the original reviewer prompt and preserves the launcher contract.")
    (p / "first.prompt.txt").write_text(prompt)
    capture.dump(p / "fixture.json", {"case": case, "model": model, "runtime": runtime,
                                      "source": str(source), "roots": [str(w) for w in roots]})
    capture.dump(p / "before.json", {str(w): capture.state(w) for w in roots})
    (p / "plan.before.md").write_text(plan)


def execute(p):
    f = json.loads((p / "fixture.json").read_text())
    cmd = ["codex", "exec", "--ignore-user-config", "--ignore-rules", "--disable", "multi_agent",
           "-m", f["model"], "-c", 'model_reasoning_effort="high"', "-c", 'service_tier="default"',
           "-c", 'web_search="disabled"', "-c", 'sandbox_mode="danger-full-access"', "--json",
           (p / "first.prompt.txt").read_text()]
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", GIT_OPTIONAL_LOCKS="0")
    if f["runtime"] == "claude":
        tools = "Bash,Read,Glob,Grep,Edit,Write,AskUserQuestion,Agent"
        agents = {"reviewer": {"description": "Independent plan reviewer", "model": f["model"],
                               "prompt": "Perform the supplied plan review from raw evidence. Stay read-only."}}
        cmd = ["claude", "-p", cmd[-1], "--model", f["model"], "--effort", "high", "--setting-sources", "",
               "--settings", '{"disableAllHooks":true}', "--strict-mcp-config", "--tools", tools,
               "--allowedTools", "Bash,Read,Glob,Grep,Edit,Write,Agent", "--agents", json.dumps(agents),
               "--permission-mode", "acceptEdits", "--permission-prompts", "none", "--add-dir", str(p),
               str(Path(f["source"])), "--output-format", "stream-json", "--forward-subagent-text", "--verbose"]
    else:
        # Capture the existing ephemeral launcher children without changing its
        # prompt, readonly sandbox, N or timeout; force the audit's fixed model.
        bindir = p / "capture-bin"
        bindir.mkdir()
        wrapper = bindir / "codex"
        real = shutil.which("codex")
        wrapper.write_text("#!/usr/bin/env python3\n" +
            "import json,os,pathlib,subprocess,sys,uuid\n" +
            f"real={real!r}; packet={str(p)!r}\n" +
            "args=sys.argv[1:]\n" +
            "if '--ephemeral' not in args: os.execv(real,[real]+args)\n" +
            "args += ['-m','gpt-6.1-sol','-c','model_reasoning_effort=\"high\"','-c','service_tier=\"default\"']\n" +
            "name=pathlib.Path(packet)/('launcher-child-'+str(uuid.uuid4()))\n" +
            "name.with_suffix('.command.json').write_text(json.dumps([real]+args))\n" +
            "prompt=sys.stdin.buffer.read(); name.with_suffix('.prompt.txt').write_bytes(prompt)\n" +
            "proc=subprocess.Popen([real]+args,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)\n" +
            "proc.stdin.write(prompt); proc.stdin.close()\n" +
            "with name.with_suffix('.jsonl').open('wb') as log:\n" +
            " for line in proc.stdout: log.write(line); log.flush(); sys.stdout.buffer.write(line); sys.stdout.buffer.flush()\n" +
            "sys.exit(proc.wait())\n")
        wrapper.chmod(0o700)
        env["PATH"] = str(bindir) + os.pathsep + env["PATH"]
        cmd[0] = real
    capture.dump(p / "first.command.json", cmd)
    start = time.monotonic()
    events = []
    with (p / "first.jsonl").open("w") as out, (p / "first.stderr.txt").open("w") as err:
        proc = subprocess.Popen(cmd, cwd=p / "work", env=env, stdout=subprocess.PIPE, stderr=err, text=True)
        for line in proc.stdout:
            out.write(line)
            out.flush()
            try:
                events.append(json.loads(line))
            except ValueError:
                pass
        rc = proc.wait()
    final, session, resolved = None, None, None
    for e in events:
        if e.get("type") == "thread.started":
            session = e["thread_id"]
        if e.get("session_id") and not e.get("parent_tool_use_id"):
            session = e["session_id"]
        if e.get("type") == "item.completed" and e.get("item", {}).get("type") == "agent_message":
            final = e["item"]["text"]
        if e.get("type") == "result":
            final, resolved = e.get("result"), e.get("modelUsage")
    if f["runtime"] == "codex" and session:
        resolved = capture.retain_codex_rollouts(p, session)
    capture.dump(p / "after.json", {w: capture.state(Path(w)) for w in f["roots"]})
    capture.dump(p / "first.summary.json", {"exit": rc, "session": session, "resolved_model": resolved,
                                           "elapsed_s": time.monotonic() - start, "final": final})
    print(json.dumps({"model": f["model"], "case": f["case"], "exit": rc,
                      "elapsed_s": round(time.monotonic() - start, 1)}), flush=True)


def audit(root):
    m = json.loads((root / "manifest.json").read_text())
    facts = []
    for model in m["models"]:
        for case in m["cases"]:
            p = root / model / case
            if not (p / "first.summary.json").exists():
                facts.append({"model": model, "case": case, "capture": "INCOMPLETE"})
                continue
            before, after = [json.loads((p / name).read_text()) for name in ["before.json", "after.json"]]
            changes = {w: sorted(k for k in before[w]["files_and_git"].keys() | after[w]["files_and_git"].keys()
                                 if before[w]["files_and_git"].get(k) != after[w]["files_and_git"].get(k)) for w in before}
            facts.append({"model": model, "case": case, "changed_paths": changes,
                          "snapshots_current": all(capture.state(Path(w)) == after[w] for w in after),
                          "plan_changed": (p / "plan.md").read_bytes() != (p / "plan.before.md").read_bytes(),
                          "native": json.loads((p / "first.summary.json").read_text())})
    capture.dump(root / "audit.json", facts)
    print(json.dumps([{k: v for k, v in f.items() if k != "native"} for f in facts], ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["setup", "run", "audit"])
    parser.add_argument("--root", required=True)
    parser.add_argument("--variant", choices=["original", "ablation"], default="original")
    parser.add_argument("--cases", nargs="+", choices=CASES, default=CASES)
    parser.add_argument("--models", nargs="+", choices=capture.MODELS, default=capture.MODELS)
    args = parser.parse_args()
    root = Path(args.root).resolve()
    if args.action == "setup":
        setup(root, args.variant, args.cases, args.models)
    elif args.action == "audit":
        audit(root)
    else:
        m = json.loads((root / "manifest.json").read_text())
        if capture.hashes(root / "source") != json.loads((root / "source-hashes.json").read_text()):
            raise SystemExit("Frozen source drift")
        packets = [root / model / case for case in m["cases"] for model in m["models"]]
        if any((p / "first.jsonl").exists() for p in packets):
            raise SystemExit("Refuse session restart")
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            list(pool.map(execute, packets))


if __name__ == "__main__":
    main()
