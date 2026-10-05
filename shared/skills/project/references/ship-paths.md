# Ship Paths — 正常送出

Prerequisite：workflow 的 Log 結案階段與 [ship-policy.md](ship-policy.md)。
本檔在第一個 outward action 及緊鄰的 Ship 摘要之前讀齊；不新增授權。
Merge 另讀 [merge-workflow.md](merge-workflow.md)，例外處置先讀 [ship-exceptions.md](ship-exceptions.md)。

> **Solo repo is not a lighter process.** One-person projects run the SAME shape as a protected-main team repo: branch → commits → review → PR → explicit merge. Never relax branch-first, the PR default, or the explicit-merge rule because "it's just me", "no one else will read this history", or "there's no protection to enforce it". 理由：repo 會移交、會加入新成員，使用者本人也會成為他人 repo 的成員——流程形狀一旦按「一人份」放寬，這些時刻就沒有秩序可交接，也養不出正式流程的手感。**這條只是防守既有規則被合理化侵蝕，不新增任何步驟。**

> **本檔通則**：下文所有 `origin` 為 canonical remote 的 **stand-in**——非 `origin` repo（如 fork 工作流）一律把 `origin` 讀作解析出的 remote（`git -C <repo> remote`：有 `origin` 用之、否則取第一個；fork 場景 push 目標與 PR/protection 查詢目標可能不同 remote，見 `log-prepare.md`「Step 1：逐 repo 狀態 + 流程偵測（先於任何 commit）」）。gh 指令多 repo 時用 `-R <owner/repo>` 或子 shell `cd` 綁定，勿靠 cwd 隱式解析。**host 假設 GitHub.com**（`gh` 走 authenticated default host、compare URL 用 `github.com`）；GHE / 自架需 `GH_HOST` + `host/owner/repo`，不在本 skill 自動處理範圍。

## Push 的執行形式

所有實際 push（含 bootstrap、force-with-lease 與重試）先把執行工具的工作目錄參數（如 `workdir`／`cwd`）
綁定已查證的 canonical repo root，再以**獨立工具呼叫**直接執行 `git push …`。不要使用 `git -C … push`，
也不要把 push 放進 wrapper、迴圈、pipeline 或 `cd … && …` 等複合指令：這些形式會在 Codex 的 outward gate
被判為 opaque，尚未執行就遭拒絕。工具若無工作目錄參數，只能先以獨立呼叫切換並查證可持續的 cwd，再獨立
push；無法可靠綁定時 STOP。下文每個 push 範例均以 target repo 的工作目錄執行；此形式不改變送出授權或
approval policy，approval 生命週期遵循 runtime 已載入的契約。

## PR 路徑

```bash
# 1. push feature branch（設 upstream）
git push -u origin <feature-branch>

# 2. 偵測既有 PR（多 repo：-R 綁定，勿靠 cwd）
gh pr view -R "$repo_slug" <feature-branch> --json url,state -q .url 2>/dev/null   # 有 → 印 URL 指向既有 PR（已 push 即更新）

# 3. 無既有 PR → 建立（base 預設 default branch）
gh pr create -R "$repo_slug" --base <default> --head <feature-branch> \
  --title "<repo-conformant semantic title>" \
  --body "<見本檔模板>"
```

- **絕不** push default branch。`gh pr merge` 僅限使用者**明說 merge** 後執行（序列見`merge-workflow.md`「Merge 最後一哩」），開 PR 當下絕不順手 merge。
- repo contract 的 commit／PR title 格式優先；沒有規定時，PR title 才沿用主要 Conventional Commit 的 subject。
- 多個 feature commit → title 取主要語意；body 列各 commit 與變更摘要。
- **fork repo**（如 `origin` 是 fork、`upstream` 是 canonical）：`gh pr create` 的 `--head` 需 `<owner>:<branch>` 格式、base/head 為不同 repo——**本 skill 不自動處理**（見檔首通則與 `log-prepare.md`「Step 1：逐 repo 狀態 + 流程偵測（先於任何 commit）」）。遇此**停下**由使用者指定 base/head，勿讓 `gh` 觸發互動式 fork/push 流程。
- **`gh` 不可用 / 未登入時的 PR 路徑**：`git push -u origin <feature-branch>`（推 feature branch 安全、不碰 default）後，因無法 `gh pr create` → **停下**，輸出 branch 名與手動開 PR 的 compare URL。**此時 `repo_slug` 不能靠 `gh repo view`（gh 已不可用），改從 remote URL 解析**（同時吃 SSH 與 HTTPS）：
  ```bash
  repo_slug=$(git -C <repo> remote get-url origin | sed -E 's#^(git@[^:]+:|ssh://[^/]+/|https?://[^/]+/)##; s#\.git$##')   # owner/repo（吃 scp-SSH / ssh:// / HTTPS）
  echo "https://github.com/$repo_slug/compare/<default>...<feature-branch>"   # 假設 github.com（見檔首 host 通則）；GHE / 自架請改 host
  ```
  **絕不**因開不了 PR 就 fallback 直推 default branch。

## 直接 push 路徑

> **這是 escape hatch，不是無保護 repo 的預設。** 確定無保護時預設仍走 PR 路徑（見 `log-prepare.md`「Step 1：逐 repo 狀態 + 流程偵測（先於任何 commit）」），只有使用者**明說**「不用 PR / 只推 branch」才落到本節。理由：跨 repo 單一形狀省掉每輪判斷、PR 留下審查紀錄與可回溯 diff，而多開一個 PR 的成本近零。**"No protection" is not a reason to skip the PR.**

僅在**明確確認無 protection、且使用者明說不用 PR** 時走，**顯式 remote + branch**（不用裸 `git push`——裸 push 受 `push.default` / `remote.pushDefault` / 非預期 upstream 影響，可能推到錯 remote 或多推 ref）：
```bash
git push -u origin <branch>   # 顯式 remote+branch+設 upstream（已有 upstream 時 -u 無害）
```
仍需 Step 4 使用者確認。push 後無 PR 動作。

## PR title / body 模板

```
<符合 target repo convention 的 PR title；無規定時用主要 Conventional Commit subject>

## 變更摘要
- <commit 1 語意>
- <commit 2 語意>

## 測試
- <測試指令與結果，如 uv run pytest …：N passed>

## Review
- <若經 /deep-review：貼「第三方審查資訊」commit range + 結論；否則略>

```

PR body 不自行加入產品 attribution。若目前 runtime 或 repo contract 明定 attribution，再依該權威加入；
不要把 Claude Code 執行標成 Codex，也不要把 Codex 執行標成 Claude Code。

舊入口的 [說法表](ship-policy.md) 與 [Branch-first 與誤 commit 搬移](ship-exceptions.md) 已分別路由；
需要其行為時讀對應檔，正常 branch-first 使用 helper。
