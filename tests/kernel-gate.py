#!/usr/bin/env python3
"""kernel-gate.py — agent contract 的 managed block 完整性掃描器。

為何需要它：契約的 kernel 必須在**三處**逐字存在——repo 根 `AGENTS.md`（工具中立入口）、
`claude/CLAUDE.md`（部署為全域 Claude 規則）、`codex/AGENTS.md`（部署為全域 Codex 指引）。root
`CLAUDE.md` 必須以唯一一行 `@AGENTS.md` 開頭，讓 Claude Code 原生展開 repo 共同正文，再附加
Claude-specific facts。普通文字指標不算 import；2026-08-24 G1c clean-room 五臂各 2/2、零探索驗證。

三份自足的代價是複本會漂移，而 skill-building-guide 明列「same fact stated in N places」
是 red flag。**這支 gate 就是把那個代價換成機檢**：漂移即紅。形狀同 xref-gate——把原本
只靠散文維持的不變式變成機械守門。

repo-resident 的 `AGENTS.md` 另帶 route block：它必須保留
`doc-find`／`doc-governance.py find` 這類可執行路由，不能退化成人工 pointer。route 與 kernel、
portable 同樣會被複製到其他 repo，因此三個 managed block 共用可攜性檢查。

用法：
    kernel-gate.py --root <dir>
    kernel-gate.py --list-finding-codes

輸出契約（tests/run.sh 依賴，勿改）：
    exit 0 — 掃描完成。**stdout 只放 blocking findings**，空輸出即通過。
    exit 2 — scanner 自身／參數／I/O 失敗。

    兩者不可混用：tests/run.sh 是 `set -uo pipefail`（無 -e），scanner 死掉時空 stdout
    會被判成「乾淨」，gate 靜默變成永遠綠。
"""

import argparse
import os
import re
import sys

# 帶 kernel block 的三個 canonical 檔——名字寫死是刻意的：漏改會讓 gate 找不到檔而判紅。
KERNEL_FILES = ("AGENTS.md", "claude/CLAUDE.md", "codex/AGENTS.md")
ROOT_CLAUDE_FILE = "CLAUDE.md"

# 只有契約檔帶 portable block（權威矩陣 + working discipline）——那層不進全域檔，
# 因為全域檔服務所有 repo、不該替別的 repo 宣告它的文件權威。
PORTABLE_FILE = "AGENTS.md"
ROUTE_FILES = ("AGENTS.md",)

MIN_RULE_LINES = 8   # safety floor 6 + fallback conventions 2
MIN_ROUTE_LINES = 2  # heading + executable route contract; blocks equal to "x" are hollow

# 逐字複本的意義在於「規則只寫一次」。這些字串是規則本體的指紋——出現在 block 之外，
# 代表有人又抄了一份（複本一旦落在 gate 管不到的地方，漂移就回來了）。
CANARIES = ("git add -A", "--no-local", "git switch -c", "`perf`, `ci`", "One writer per work item.")
REQUIRED_KERNEL_RULES = (
    "One writer per work item.",
    "separate branch/worktree",
    "Dossier Steward",
    "Dossier delta",
    "Do NOT create a dossier",
    "`git cherry-pick`",
)

# 封閉集合：每個 blocking 分支必須回傳其中一碼；tests/run.sh 會執行 RED fixtures 並驗證
# 每一碼都真的被命中。新增 finding 分支時只加 code、不加 fixture，meta-test 必紅。
FINDING_CODES = (
    "KERNEL_FILE_MISSING", "KERNEL_MARKER_COUNT", "KERNEL_MARKER_ORDER",
    "KERNEL_CANARY_OUTSIDE", "KERNEL_MIN_RULES", "KERNEL_REQUIRED_RULE", "KERNEL_DRIFT",
    "ROUTE_MARKER_COUNT", "ROUTE_MARKER_ORDER", "ROUTE_EMPTY",
    "ROUTE_MIN_RULES", "ROUTE_EXECUTABLE", "ROUTE_MISPLACED",
    "ROOT_CLAUDE_FILE_MISSING", "ROOT_CLAUDE_IMPORT_COUNT", "ROOT_CLAUDE_IMPORT_ORDER",
    "ROOT_CLAUDE_MANAGED_BLOCK",
    "PORTABLE_FILE_MISSING", "PORTABLE_MARKER_COUNT", "PORTABLE_MARKER_ORDER",
    "PORTABLE_EMPTY", "PORTABLE_NESTED_KERNEL", "PORTABLE_MISPLACED",
    "PORTABILITY_PRIVATE", "PORTABILITY_XREF",
)


def finding(code, message):
    if code not in FINDING_CODES:
        raise RuntimeError("undeclared finding code: %s" % code)
    return "[%s] %s" % (code, message)


def marker_re(name, kind):
    # 版本只掛在 start（`:start v1`）——end 不帶版本，否則同一個 block 有兩個要同步的
    # 版本號，改版時漏改一邊就變成「marker 不成對」這種看不出真因的紅。
    suffix = r" v\d+" if kind == "start" else ""
    return re.compile(r"<!-- agent-contract:%s:%s%s -->" % (re.escape(name), kind, suffix))


def extract(text, name):
    """回傳 (block_body, findings)。markers 異常時 body 為 None。"""
    starts = list(marker_re(name, "start").finditer(text))
    ends = list(marker_re(name, "end").finditer(text))
    if len(starts) != 1 or len(ends) != 1:
        return None, [finding("%s_MARKER_COUNT" % name.upper(),
                              "%s block 的 marker 不是各恰一次（start=%d end=%d）"
                              % (name, len(starts), len(ends)))]
    if starts[0].start() > ends[0].start():
        return None, [finding("%s_MARKER_ORDER" % name.upper(),
                              "%s block 的 start marker 在 end 之後" % name)]
    return text[starts[0].end():ends[0].start()], []


def read(root, rel):
    path = os.path.join(root, rel)
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def scan(root):
    findings = []
    bodies = {}

    try:
        root_claude = read(root, ROOT_CLAUDE_FILE)
    except FileNotFoundError:
        findings.append(finding("ROOT_CLAUDE_FILE_MISSING", "%s: 檔案不存在——Claude 無法 import repo 契約" % ROOT_CLAUDE_FILE))
    else:
        imports = re.findall(r"(?m)^\s*@AGENTS\.md\s*$", root_claude)
        if len(imports) != 1:
            findings.append(finding("ROOT_CLAUDE_IMPORT_COUNT", "%s: @AGENTS.md import 必須恰好一行（實際 %d）"
                                    % (ROOT_CLAUDE_FILE, len(imports))))
        first = next((line.strip() for line in root_claude.splitlines() if line.strip()), "")
        if first != "@AGENTS.md":
            findings.append(finding("ROOT_CLAUDE_IMPORT_ORDER", "%s: 第一個非空白行必須是 @AGENTS.md" % ROOT_CLAUDE_FILE))
        if any(marker_re(name, "start").search(root_claude) for name in ("kernel", "route", "portable")):
            findings.append(finding("ROOT_CLAUDE_MANAGED_BLOCK", "%s: import 後不得再複製 managed block" % ROOT_CLAUDE_FILE))

    for rel in KERNEL_FILES:
        try:
            text = read(root, rel)
        except FileNotFoundError:
            findings.append(finding("KERNEL_FILE_MISSING", "%s: 檔案不存在——kernel 需要在三個 canonical 來源逐字存在" % rel))
            continue
        body, errs = extract(text, "kernel")
        findings.extend("%s: %s" % (rel, e) for e in errs)
        if body is None:
            continue
        bodies[rel] = body

        # canary：規則本體不得在 block 之外再出現一份
        outside = text[:text.index("<!-- agent-contract:kernel:start")] + \
            text[text.index("<!-- agent-contract:kernel:end"):]
        for canary in CANARIES:
            if canary in outside:
                findings.append(finding("KERNEL_CANARY_OUTSIDE", "%s: 規則指紋 %r 出現在 kernel block 之外——又抄了一份？"
                                % (rel, canary)))

    if len(bodies) == len(KERNEL_FILES):
        # 條目數下限：三份都缺 block 時「空 == 空」會通過，這條是防那個假綠的關鍵
        rules = [ln for ln in bodies[KERNEL_FILES[0]].splitlines() if ln.startswith("- ")]
        if len(rules) < MIN_RULE_LINES:
            findings.append(finding("KERNEL_MIN_RULES", "kernel block 只有 %d 條規則行（<%d）——內容被掏空？"
                            % (len(rules), MIN_RULE_LINES)))
        ref = bodies[KERNEL_FILES[0]]
        missing = [rule for rule in REQUIRED_KERNEL_RULES if rule not in ref]
        if missing:
            findings.append(finding("KERNEL_REQUIRED_RULE", "kernel block 缺跨 runtime dossier 規則指紋: %s"
                            % ", ".join(repr(item) for item in missing)))
        for rel in KERNEL_FILES[1:]:
            if bodies[rel] != ref:
                findings.append(finding("KERNEL_DRIFT", "%s 的 kernel block 與 %s 不是逐字相同——複本已漂移"
                                % (rel, KERNEL_FILES[0])))

    route_bodies = {}
    for rel in ROUTE_FILES:
        try:
            route_text = read(root, rel)
        except FileNotFoundError:
            continue
        route_body, errs = extract(route_text, "route")
        findings.extend("%s: %s" % (rel, e) for e in errs)
        if route_body is not None:
            if not route_body.strip():
                findings.append(finding("ROUTE_EMPTY", "%s: route block 是空的" % rel))
            route_rules = [line for line in route_body.splitlines() if line.strip()]
            if len(route_rules) < MIN_ROUTE_LINES:
                findings.append(finding("ROUTE_MIN_RULES", "%s: route block 只有 %d 條規則行（<%d）——內容被掏空？"
                                % (rel, len(route_rules), MIN_ROUTE_LINES)))
            if not any(token in route_body for token in ('doc-find', 'doc-governance.py find')):
                findings.append(finding("ROUTE_EXECUTABLE", "%s: route block 缺 executable route 規則行" % rel))
            route_bodies[rel] = route_body
    for rel in sorted(set(KERNEL_FILES) - set(ROUTE_FILES)):
        try:
            text = read(root, rel)
        except FileNotFoundError:
            continue
        if marker_re("route", "start").search(text):
            findings.append(finding("ROUTE_MISPLACED", "%s: route block 只允許出現在 repo-resident 契約" % rel))

    # 契約檔的 portable block：存在、非空、且不與 kernel 巢狀
    try:
        text = read(root, PORTABLE_FILE)
    except FileNotFoundError:
        findings.append(finding("PORTABLE_FILE_MISSING", "%s: 檔案不存在" % PORTABLE_FILE))
    else:
        body, errs = extract(text, "portable")
        findings.extend("%s: %s" % (PORTABLE_FILE, e) for e in errs)
        if body is not None:
            if not body.strip():
                findings.append(finding("PORTABLE_EMPTY", "%s: portable block 是空的" % PORTABLE_FILE))
            if "agent-contract:kernel" in body:
                findings.append(finding("PORTABLE_NESTED_KERNEL", "%s: kernel block 巢狀在 portable 之內——兩者必須並列"
                                % PORTABLE_FILE))
        findings.extend(portability(text))

    for rel in sorted(set(KERNEL_FILES) - {PORTABLE_FILE}):
        try:
            text = read(root, rel)
        except FileNotFoundError:
            continue
        if marker_re("portable", "start").search(text):
            findings.append(finding("PORTABLE_MISPLACED", "%s: portable block 只允許出現在 %s" % (rel, PORTABLE_FILE)))

    return findings


# 三個 managed block 都會被複製到別的 repo。`## Repo specifics` 刻意在 block 之外，
# 本 repo 那節本來就會寫到 dotsync／~/.dotfiles，掃它只會製造假紅。
PRIVATE_TOKENS = ("~/.dotfiles", "~/.claude", "~/.codex", "/Users/",
                  "/project", "/deep-review", "/ready4quit", "/handoff",
                  "ship-state.sh", "dotsync")
# 「見 `X`「Y」」形狀的指標：在 dotfiles 內 xref-gate 會判它活著，安裝到別的 repo 卻是死的
# ——既有 gate 看不見的假綠。契約檔一律不得依賴這種跨檔指標。
XREF_SHAPE = re.compile(r"`[^`\n]+?\.(?:md|sh)`[「『]")


def portability(text):
    out = []
    for name in ("kernel", "route", "portable"):
        body, _ = extract(text, name)
        if body is None:
            continue
        for token in PRIVATE_TOKENS:
            if token in body:
                out.append(finding("PORTABILITY_PRIVATE", "%s: %s block 含私人路徑 %r——安裝到別的 repo 就是死的"
                           % (PORTABLE_FILE, name, token)))
        if XREF_SHAPE.search(body):
            out.append(finding("PORTABILITY_XREF", "%s: %s block 含跨檔指標句型——契約必須自足"
                       % (PORTABLE_FILE, name)))
    return out


def main(argv):
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--root")
    ap.add_argument("--list-finding-codes", action="store_true")
    args = ap.parse_args(argv)
    if args.list_finding_codes:
        print("\n".join(FINDING_CODES))
        return 0
    if not args.root:
        ap.error("--root is required unless --list-finding-codes is used")
    root = os.path.abspath(args.root)
    if not os.path.isdir(root):
        print("--root 不是目錄：%s" % root, file=sys.stderr)
        return 2
    try:
        findings = scan(root)
    except OSError as exc:
        print("掃描失敗：%s" % exc, file=sys.stderr)
        return 2
    for f in findings:
        print(f)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
