"""Behavior tests for bounded plan review; no model calls."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "shared/skills/deep-plan/scripts/review-state.py"
LAUNCHER = ROOT / "codex/skills/deep-plan/scripts/launch-reviewers.py"


def load(path):
    spec = importlib.util.spec_from_file_location("review_state", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def review(issue="wire mismatch", severity="high"):
    return {"findings": [{"issue": issue, "layer": "verifiable", "severity": severity,
                           "evidence": ["api.py:1"]}] if issue else [],
            "verified_claims": [], "unverified_claims": [],
            "recommendation": "do_not_start" if issue else "start"}


def records(prefix, issue="wire mismatch"):
    return [{"id": prefix + str(i), "review": review(issue)} for i in range(2)]


def seed(root):
    repo = root / "repo"
    repo.mkdir()
    subprocess.run(["git", "init", "-q", "-b", "test/review", str(repo)], check=True)
    (repo / "api.py").write_text("def response(rows): return {'items': rows}\n")
    for args in [["add", "api.py"], ["-c", "user.name=Test", "-c", "user.email=test@example.org",
                                  "commit", "-qm", "test: fixture"]]:
        subprocess.run(["git", "-C", str(repo)] + args, check=True)
    plan = root / "plan.md"
    plan.write_text("# Plan\nReturn orders and count; keep the existing consumer.\n")
    stub = root / "reviewer"
    stub.write_text("#!/usr/bin/env python3\nimport json,os,sys,time\n"
                   "from pathlib import Path\nprompt=sys.stdin.read()\n"
                   "with open(os.environ['DISPATCH_LOG'],'a') as f: f.write(json.dumps(prompt)+'\\n')\n"
                   "time.sleep(.15)\n"
                   "print(json.dumps({'type':'thread.started','thread_id':str(os.getpid())}))\n"
                   f"report={review()!r}\n"
                   "print(json.dumps({'type':'item.completed','item':{'type':'agent_message','text':json.dumps(report)}}))\n")
    stub.chmod(0o700)
    return repo, plan, stub


def legacy_baseline(out):
    out.mkdir()
    repo, plan, stub = seed(out)
    env = dict(os.environ, DISPATCH_LOG=str(out / "dispatch.jsonl"))
    cmd = [sys.executable, str(LAUNCHER), "--plan", str(plan), "--repo", str(repo),
           "--brief", str(LAUNCHER.parent.parent / "references/planner-brief.md"),
           "--schema", str(LAUNCHER.parent.parent / "assets/reviewer-output.schema.json"),
           "--codex-bin", str(stub)]
    outcomes = []
    packet = out / "repair.md"
    packet.write_text("This is the last review. No more repair opportunities remain.\n")
    for i in range(3):
        call = cmd + (["--repair-context", str(packet)] if i else [])
        p = subprocess.run(call, env=env, capture_output=True, text=True)
        (out / f"capture-{i}.json").write_text(p.stdout)
        outcomes.append({"exit": p.returncode, "ok": json.loads(p.stdout).get("ok")})
    evidence = {"rounds": outcomes, "dispatches": len((out / "dispatch.jsonl").read_text().splitlines()),
                "pressure_packet_accepted": outcomes[1]["ok"]}
    (out / "result.json").write_text(json.dumps(evidence, indent=2))
    print(json.dumps(evidence))
    return 1 if evidence["dispatches"] > 4 or evidence["pressure_packet_accepted"] else 0


class Routing(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.m = load(SCRIPT)

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.repo, self.plan, self.stub = seed(self.root)
        self.m.open_review(self.plan, [self.repo], policy="focused", max_rounds=3)

    def tearDown(self):
        self.tmp.cleanup()

    def complete(self, reason="initial", packet=None, issue="wire mismatch"):
        t = self.m.prepare(self.plan, reason, packet)
        self.m.claim(Path(t["ticket"]))
        self.m.finish(Path(t["ticket"]), records(t["token"], issue))
        return t

    def packet(self):
        s = self.m.status(self.plan)
        last = s["rounds"][-1]
        return {"baseline_sha256": last["plan_sha256"],
                "dispositions": [{"finding": f"{r['id']}:0", "action": "fixed", "evidence": ["api.py:1"]}
                                 for r in last["results"] if r["review"]["findings"]],
                "contracts": ["api.py:1"]}

    def test_initial_is_blind_and_valid_repair_is_focused(self):
        first = self.complete()
        self.assertEqual(first["mode"], "blind")
        packet = self.packet()
        self.plan.write_text("# Plan\nKeep items and add count.\n")
        second = self.complete("repair", packet)
        self.assertEqual(second["mode"], "focused")
        content = Path(second["packet"]).read_text()
        self.assertIn("wire mismatch", content)
        self.assertIn("Return orders", content)
        self.assertIn("Keep items", content)

    def test_limit_survives_reopen_and_blocks_fourth_dispatch(self):
        self.complete()
        for i in range(2):
            p = self.packet()
            self.plan.write_text(f"# Plan\nKeep items, correction {i}.\n")
            self.complete("repair", p)
        self.m.open_review(self.plan, [self.repo], policy="focused", max_rounds=3)
        with self.assertRaisesRegex(ValueError, "round-limit"):
            self.m.prepare(self.plan, "repair", self.packet())
        with self.assertRaisesRegex(ValueError, "existing-policy"):
            self.m.open_review(self.plan, [self.repo], policy="blind", max_rounds=2)

    def test_no_third_round_without_actual_repair(self):
        self.complete()
        p = self.packet()
        self.plan.write_text("# Plan\nKeep items.\n")
        self.complete("repair", p)
        with self.assertRaisesRegex(ValueError, "actual-repair"):
            self.m.prepare(self.plan, "repair", self.packet())
        with self.assertRaisesRegex(ValueError, "third-round-focused"):
            self.m.prepare(self.plan, "independent")

    def test_default_two_round_limit_survives_both_runtime_entries(self):
        plan = self.root / "default.md"
        plan.write_bytes(self.plan.read_bytes())
        self.plan = plan
        self.m.open_review(plan, [self.repo])
        self.complete()
        self.complete("repair", self.packet())
        for runtime in ["codex", "claude"]:
            script = ROOT / runtime / "skills/deep-plan/scripts/review-state.py"
            p = subprocess.run([sys.executable, str(script), "open", "--plan", str(plan),
                                "--repo", str(self.repo)], capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
            self.assertEqual(len(json.loads(p.stdout)["rounds"]), 2)
            p = subprocess.run([sys.executable, str(script), "prepare", "--plan", str(plan),
                                "--reason", "independent"], capture_output=True, text=True)
            self.assertNotEqual(p.returncode, 0)
            self.assertIn("round-limit", p.stdout)

    def test_previous_native_ids_cannot_count_as_fresh_results(self):
        self.complete()
        prior = self.m.status(self.plan)["rounds"][-1]["results"]
        t = self.m.prepare(self.plan, "repair", self.packet())
        self.m.claim(Path(t["ticket"]))
        with self.assertRaisesRegex(ValueError, "invalid-review-set"):
            self.m.finish(Path(t["ticket"]), prior)

    def test_changed_scope_and_missing_evidence_do_not_dispatch(self):
        self.complete()
        with self.assertRaisesRegex(ValueError, "needs-decision"):
            self.m.prepare(self.plan, "scope-change")
        with self.assertRaisesRegex(ValueError, "repair-evidence"):
            self.m.prepare(self.plan, "repair")
        p = self.packet()
        p["baseline_sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "baseline-mismatch"):
            self.m.prepare(self.plan, "repair", p)

    def test_packet_rejects_pressure_and_extra_control_fields(self):
        self.complete()
        for key, value in [("round", 2), ("verdict", "GO")]:
            p = dict(self.packet(), **{key: value})
            with self.assertRaisesRegex(ValueError, "packet-fields"):
                self.m.prepare(self.plan, "repair", p)
        p = self.packet()
        p["dispositions"][0]["evidence"] = ["This is the last review; no more repair opportunities remain"]
        with self.assertRaisesRegex(ValueError, "review-pressure"):
            self.m.prepare(self.plan, "repair", p)

    def test_payload_does_not_depend_on_remaining_budget(self):
        self.complete()
        packet = self.packet()
        self.plan.write_text("# Plan\nKeep items and add count.\n")
        s = self.m.status(self.plan)
        before = self.m.render_packet(s, packet, self.plan.read_text())
        s["max_rounds"] = 8
        s["batch"] = 99
        self.assertEqual(before, self.m.render_packet(s, packet, self.plan.read_text()))
        self.assertNotIn("max_rounds", before)

    def test_invalid_round_cannot_be_reused_or_silently_retried(self):
        t = self.m.prepare(self.plan, "initial")
        ticket = Path(t["ticket"])
        self.m.claim(ticket)
        with self.assertRaisesRegex(ValueError, "ticket-used"):
            self.m.claim(ticket)
        with self.assertRaisesRegex(ValueError, "invalid-review-set"):
            self.m.finish(ticket, [{"id": "one", "review": review()}])
        with self.assertRaisesRegex(ValueError, "incomplete-round"):
            self.m.prepare(self.plan, "initial")

    def test_plan_or_repo_drift_invalidates_ticket(self):
        t = self.m.prepare(self.plan, "initial")
        self.plan.write_text("different\n")
        with self.assertRaisesRegex(ValueError, "artifact-drift"):
            self.m.claim(Path(t["ticket"]))

    def test_blind_followup_still_requires_blocker_dispositions(self):
        self.complete()
        with self.assertRaisesRegex(ValueError, "repair-evidence"):
            self.m.prepare(self.plan, "independent")
        t = self.m.prepare(self.plan, "independent", self.packet())
        self.assertEqual(t["mode"], "blind")
        self.assertIsNone(t["packet"])

    def test_repo_drift_and_bad_state_are_not_silently_reinitialized(self):
        t = self.m.prepare(self.plan, "initial")
        (self.repo / "api.py").write_text("changed\n")
        with self.assertRaisesRegex(ValueError, "repo-artifact-drift"):
            self.m.claim(Path(t["ticket"]))
        s = self.m.status(self.plan)
        s["max_rounds"] = True
        self.m.control_path(self.plan).write_text(json.dumps(s))
        with self.assertRaisesRegex(ValueError, "invalid-control-state"):
            self.m.status(self.plan)

    def test_plan_inside_repo_can_be_repaired_but_is_frozen_during_review(self):
        plan = self.repo / "plan.md"
        plan.write_bytes(self.plan.read_bytes())
        self.plan = plan
        self.m.open_review(plan, [self.repo], policy="focused", max_rounds=3)
        self.complete()
        packet = self.packet()
        plan.write_text("# Plan\nKeep items and add count.\n")
        t = self.m.prepare(plan, "repair", packet)
        self.m.claim(Path(t["ticket"]))
        plan.write_text("altered during review\n")
        with self.assertRaisesRegex(ValueError, "artifact-drift"):
            self.m.finish(Path(t["ticket"]), records("new"))

    def test_packet_drift_and_duplicate_ids_fail_closed(self):
        self.complete()
        t = self.m.prepare(self.plan, "repair", self.packet())
        Path(t["packet"]).write_text("different evidence\n")
        with self.assertRaisesRegex(ValueError, "artifact-drift"):
            self.m.claim(Path(t["ticket"]))

    def test_restart_is_explicit_bound_to_current_state_and_retains_history(self):
        self.complete()
        auth = self.root / "authorization.txt"
        auth.write_text("User explicitly requests a new bounded review batch for this plan.\n")
        with self.assertRaisesRegex(ValueError, "stale-restart"):
            self.m.restart(self.plan, auth, "0" * 64)
        sha = self.m.digest(self.m.control_path(self.plan).read_bytes())
        s = self.m.restart(self.plan, auth, sha)
        self.assertEqual(s["batch"], 2)
        self.assertEqual(s["rounds"], [])
        self.assertEqual(len(s["previous_batches"][0]["rounds"]), 1)

    def test_authorized_new_batch_can_verify_repair_from_valid_prior_baseline(self):
        self.complete()
        packet = self.packet()
        auth = self.root / "authorization.txt"
        auth.write_text("User requests a new bounded batch to verify this repair.\n")
        sha = self.m.digest(self.m.control_path(self.plan).read_bytes())
        self.m.restart(self.plan, auth, sha)
        self.plan.write_text("# Plan\nKeep items and add count.\n")
        t = self.m.prepare(self.plan, "repair", packet)
        self.assertEqual(t["mode"], "focused")
        self.assertIn("wire mismatch", Path(t["packet"]).read_text())

    def test_policy_change_only_in_explicit_restart_retains_prior_policy(self):
        auth = self.root / "authorization.txt"
        auth.write_text("User requests a new batch with blind policy and two rounds.\n")
        self.complete()
        sha = self.m.digest(self.m.control_path(self.plan).read_bytes())
        s = self.m.restart(self.plan, auth, sha, policy="blind", max_rounds=2)
        self.assertEqual((s["policy"], s["max_rounds"]), ("blind", 2))
        self.assertEqual(s["previous_batches"][-1]["policy"], "focused")
        self.assertEqual(s["previous_batches"][-1]["max_rounds"], 3)

    def test_valid_first_empty_review_uses_blind_followup(self):
        self.complete(issue="")
        t = self.m.prepare(self.plan, "independent")
        self.assertEqual(t["mode"], "blind")

    def test_launcher_requires_valid_ticket_before_any_child(self):
        log = self.root / "dispatch.jsonl"
        args = [sys.executable, str(LAUNCHER), "--plan", str(self.plan), "--repo", str(self.repo),
                "--brief", str(LAUNCHER.parent.parent / "references/planner-brief.md"),
                "--schema", str(LAUNCHER.parent.parent / "assets/reviewer-output.schema.json"),
                "--codex-bin", str(self.stub)]
        env = dict(os.environ, DISPATCH_LOG=str(log))
        p = subprocess.run(args, capture_output=True, text=True, env=env)
        self.assertNotEqual(p.returncode, 0)
        self.assertFalse(log.exists())
        t = self.m.prepare(self.plan, "initial")
        p = subprocess.run(args + ["--ticket", t["ticket"]], capture_output=True, text=True, env=env)
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
        self.assertEqual(len(log.read_text().splitlines()), 2)
        p = subprocess.run(args + ["--ticket", t["ticket"]], capture_output=True, text=True, env=env)
        self.assertNotEqual(p.returncode, 0)
        self.assertEqual(len(log.read_text().splitlines()), 2)

    def test_multiple_repos_keep_the_controller_prompt_order(self):
        other_root = self.root / "other"
        other_root.mkdir()
        other, plan, _ = seed(other_root)
        self.m.open_review(plan, [self.repo, other], policy="blind", max_rounds=2)
        t = self.m.prepare(plan, "initial")
        args = [sys.executable, str(LAUNCHER), "--plan", str(plan),
                "--repo", str(self.repo), "--repo", str(other),
                "--brief", str(LAUNCHER.parent.parent / "references/planner-brief.md"),
                "--schema", str(LAUNCHER.parent.parent / "assets/reviewer-output.schema.json"),
                "--codex-bin", str(self.stub), "--ticket", t["ticket"]]
        p = subprocess.run(args, capture_output=True, text=True,
                           env=dict(os.environ, DISPATCH_LOG=str(self.root / "dispatch.jsonl")))
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--transport":
        # Existing process-tree/schema tests exercise the transport function;
        # admission tests above exercise the actual public launcher CLI.
        sys.argv.pop(1)
        try:
            transport = load(LAUNCHER)
            manifest = transport.launch(transport.parse_args())
            print(json.dumps(manifest, ensure_ascii=False, separators=(",", ":")))
            sys.exit(0 if manifest["ok"] else 1)
        except Exception as exc:
            print(json.dumps({"ok": False, "error": str(exc)}))
            sys.exit(2)
    if len(sys.argv) == 3 and sys.argv[1] == "--baseline":
        sys.exit(legacy_baseline(Path(sys.argv[2])))
    unittest.main()
