"""Normalize saved native traces; behavior and mutation order still need review.

Credit rates are the 2026-10-02 Standard rates, not subscription quota rates.
"""

import hashlib
import json
import pathlib
import re
import sys


def texts(v):
    if isinstance(v, str):
        return v
    if isinstance(v, list):
        return "\n".join(
            texts(x.get("text", x.get("content", "")))
            if isinstance(x, dict)
            else texts(x)
            for x in v
        )
    return ""


def metrics(p, tag, source):
    summary = json.loads((p / (tag + ".summary.json")).read_text())
    events = [
        json.loads(l) for l in (p / (tag + ".timed.jsonl")).read_text().splitlines()
    ]
    starts = {}
    calls = []
    other = []
    errors = []
    tools = []

    def result(ident, command, out, end, kind):
        tools.append(
            {
                "command": command,
                "kind": kind,
                "start_s": starts.get(ident),
                "end_s": end,
            }
        )
        if "read-reference.py" not in command:
            return
        if "REFERENCE\t" not in out:
            other.append({"command": command, "output": out[:150]})
            return
        blocks = re.findall(
            r"^REFERENCE\t([^\n]+)\nSHA256\t([^\n]+)\nTOTAL\t(\d+)\nRANGE\t(\d+)\t(\d+)\nBEGIN\n",
            out,
            re.MULTILINE,
        )
        if len(blocks) != 1:
            errors.append("reader tool result has " + str(len(blocks)) + " envelopes")
        if not blocks:
            return
        name, sha, total, a, b = blocks[0]
        body = out[out.index("BEGIN\n") + 6 :]
        complete = re.findall(r"^L(\d{6})\t([^\n]*)(?:\n|$)", body, re.MULTILINE)
        footer = re.search(r"^((?:NEXT|EOF)\t\d+)\s*$", body, re.MULTILINE)
        path = source / "shared/skills/project/references" / name
        direct = pathlib.Path(name).name == name and name.endswith(".md")
        valid = (
            direct
            and path.is_file()
            and hashlib.sha256(path.read_bytes()).hexdigest() == sha
        )
        source_lines = (
            path.read_text().splitlines() if direct and path.is_file() else []
        )
        complete = [
            (n, line)
            for n, line in complete
            if 1 <= int(n) <= len(source_lines) and source_lines[int(n) - 1] == line
        ]
        call = {
            "reference": name,
            "sha_ok": valid,
            "total": int(total),
            "range": [int(a), int(b)],
            "visible_lines": [int(x[0]) for x in complete],
            "footer": footer.group(1) if footer else None,
            "bytes": len(out.encode()),
            "start_s": starts.get(ident),
            "end_s": end,
            "command": command,
        }
        calls.append(call)

    for timed in events:
        e = timed["event"]
        i = e.get("item", {})
        t = timed["elapsed_s"]
        if e.get("type") == "item.started":
            starts[i.get("id")] = t
        if e.get("type") == "item.completed" and i.get("type") == "command_execution":
            result(i["id"], i["command"], i.get("aggregated_output", ""), t, "Bash")
        if e.get("type") == "item.completed" and i.get("type") == "mcp_tool_call":
            result(
                i["id"],
                i.get("arguments", {}).get("command", ""),
                texts((i.get("result") or {}).get("content", [])),
                t,
                "MCP Bash",
            )
        if e.get("type") == "item.completed" and i.get("type") == "file_change":
            tools.append(
                {"kind": "file_change", "changes": i.get("changes"), "end_s": t}
            )
        if e.get("type") == "assistant":
            for b in e.get("message", {}).get("content", []):
                if b.get("type") == "tool_use":
                    starts[b["id"]] = t
                    starts[b["id"] + "command"] = b.get("input", {}).get(
                        "command", json.dumps(b.get("input", {}))
                    )
                    starts[b["id"] + "kind"] = b.get("name")
        if e.get("type") == "user":
            for b in e.get("message", {}).get("content", []):
                if b.get("type") == "tool_result":
                    ident = b["tool_use_id"]
                    result(
                        ident,
                        starts.get(ident + "command", ""),
                        texts(b.get("content")),
                        t,
                        starts.get(ident + "kind", ""),
                    )
    coverage = {}
    eofs = {}
    for c in calls:
        coverage.setdefault(c["reference"], []).extend(c["visible_lines"])
        if c["footer"] and c["footer"].startswith("EOF"):
            eofs[c["reference"]] = c["end_s"]
        if not c["sha_ok"]:
            errors.append("source SHA mismatch: " + c["reference"])
    for name, lines in coverage.items():
        n = next(c["total"] for c in calls if c["reference"] == name)
        if lines != list(range(1, n + 1)):
            errors.append("non-contiguous/duplicate/missing lines: " + name)
        if name not in eofs:
            errors.append("no EOF: " + name)
    summary.update(
        {
            "reader_calls": len(calls),
            "reader_bytes": sum(c["bytes"] for c in calls),
            "reader_other_attempts": other,
            "reader_protocol_errors": errors,
            "reference_elapsed_s": calls[-1]["end_s"] - calls[0]["start_s"]
            if calls
            else None,
            "references": list(coverage),
            "eofs_s": eofs,
            "calls": calls,
            "tools": tools,
        }
    )
    if (p / "inject-truncation").exists():
        observed = any(c["footer"] is None for c in calls)
        summary["host_truncation_observed"] = observed
        summary["host_truncation_protocol"] = (
            ("FAIL" if errors else "PASS")
            if observed
            else "INCONCLUSIVE: injection not observed"
        )
        # This only grades line continuity. Review mutation timing separately.
    u = summary["incremental_usage"]
    if summary["runtime"] == "codex":
        r = {"gpt-6.1-sol": (50, 2.5, 250), "gpt-5.6-sol": (100, 10, 500)}[
            summary["model"]
        ]
        summary["credits_equivalent"] = (
            (u["input_tokens"] - u["cached_input_tokens"]) * r[0]
            + u["cached_input_tokens"] * r[1]
            + u["output_tokens"] * r[2]
        ) / 1e6
        summary["input_total"] = u["input_tokens"]
    else:
        summary["input_total"] = (
            u["input_tokens"]
            + u["cache_creation_input_tokens"]
            + u["cache_read_input_tokens"]
        )
    (p / (tag + ".metrics.json")).write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n"
    )
    return summary


def required_references(case, source):
    """Expected route, independent of the agent's claimed reads or final verdict."""
    refs = source / "shared/skills/project/references"
    if (refs / "log-prepare.md").exists():
        if case == "noop":
            return {"workflow.md", "log-workflow.md", "ship-policy.md"}
        if case in {"spec", "transfer"}:
            return {"workflow.md", "authority.md", "dossier.md", case + "-workflow.md"}
        expected = {"workflow.md", "log-workflow.md", "ship-policy.md",
                    "authority.md", "dossier.md", "log-prepare.md", "ship-paths.md"}
        if case.startswith("merge"):
            expected.add("merge-workflow.md")
        return expected
    expected = {"workflow.md", "dossier.md"}
    if case not in {"spec", "transfer"}:
        expected |= {"log-workflow.md", "ship-paths.md"}
    elif (refs / (case + "-workflow.md")).exists():
        expected.add(case + "-workflow.md")
    return expected


def main():
    for arg in sys.argv[1:]:
        root = pathlib.Path(arg)
        manifest = json.loads((root / "manifest.json").read_text())
        source = pathlib.Path(manifest["source"])
        for model in manifest["models"]:
            for tag in ["first", "reuse"]:
                p = root / model
                if not (p / (tag + ".summary.json")).exists():
                    continue
                m = metrics(p, tag, source)
                required = required_references(manifest["case"], source)
                if tag == "first":
                    missing = required - set(m["references"])
                    m["reader_protocol_errors"] += [
                        "missing mode-required EOF: " + name for name in sorted(missing)
                    ]
                    (p / (tag + ".metrics.json")).write_text(
                        json.dumps(m, ensure_ascii=False, indent=2) + "\n"
                    )
                print(
                    json.dumps(
                        {
                            "root": root.name,
                            "model": model,
                            "tag": tag,
                            "readers": m["reader_calls"],
                            "reader_bytes": m["reader_bytes"],
                            "refs": m["references"],
                            "errors": m["reader_protocol_errors"],
                            "input": m["input_total"],
                            "output": m["incremental_usage"]["output_tokens"],
                            "credits": m.get("credits_equivalent"),
                            "reference_s": m["reference_elapsed_s"],
                            "turn_s": m["elapsed_s"],
                        },
                        ensure_ascii=False,
                    )
                )


if __name__ == "__main__":
    main()
