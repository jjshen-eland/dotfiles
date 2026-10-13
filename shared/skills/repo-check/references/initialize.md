# 一次組織文件基線初始化

## Safety and authorization

**Only an explicit initialization request enters this mode.** Empty findings/policy selection/file creation
permission do not authorize push. Do not invoke another shipping skill implicitly. Obey the kernel and stricter
target contracts; a skill cannot override them. A target still absolutely prohibiting bootstrap push allows
preparation only; report that conflict.

**Document-baseline creation only, once.** No product code/data, arbitrary existing HEAD/ancestors, PR/merge,
remote/default-setting changes, CI enrollment, bypass or later pushes. Never disable hooks/checks. Reconcile
read-only state after an ambiguous push result before considering any new action.

## 前提與內容

先完成 workflow 的目標／policy／remote 盤點。Built-in target 必須是 `github.com/elandcomtw/<repo>`，
intended default=`main`；metadata 衝突／不可見時停止並列來源。替代 policy 必須明示其 bootstrap/default
要求才能初始化，不能借 elandcomtw 的 main 規則。

- 所有實際 push destinations 唯一且屬核准 target；沒有 remote／rewrite／fork 目標含糊則停止。
- Commit／push 前核對 selected policy 的 effective 作者設定與來源。作者未配置、Git 自動捏造、佔位／假信箱或已證實身分不合規時停止，不先推後補。不自動改姓名／信箱；工作歸屬不能證明時先取得必要身分確認。
- `git ls-remote --heads --tags <remote>` 成功且零 refs，另核對 provider branch/default metadata。
  本機沒有任何既有 commit、staged 變更或未核准檔案；有產品 HEAD 不選它或 ancestor 作 baseline。
- 查有效 creation restrictions、required checks/workflows、classic protection 與所有 org/repo ruleset。
  空结果也要確認 query 正確、來源完整；缺 branch 的可解釋 404 與 policy 不可見分開判斷。
  含糊 403/404、未豁免 create 的 required checks、creation restriction／schema 不明均停止。
  不啟用／移除 `required_check_profile`，不使用 bypass。
- Allowlist：`README.md`、`CONTRIBUTING.md`、`.gitignore`、`AGENTS.md`、`CLAUDE.md`，
  只建立當批核准子集合。README 填用途／初始狀態；CONTRIBUTING 描述 feature branch／PR、驗證
  入口及規範來源；agent 文件依 adopted contract，不複製無來源規則。不加入 workflow、依賴、產品、
  license 或真實環境設定。

尚未 Git init 時，只有本機初始化獲授權後才 `git init -b chore/org-baseline`。已 init 但 unborn 時
在非 default 的 `chore/org-baseline` 或 target 規定 feature branch 準備；不在 main commit。
不覆寫既有檔案，不把他人變更當本批；未知來源列衝突並停止 mutation。

## 可 review 的結果與核准

先展示 policy/template revision、exact target、default、檔案完整 diff 與已驗前提。
當輪已明示核准 exact 內容、target、push action，可接續而不重問。
「準備初始化」「內建規範」「ship it」不是本批 push 授權；先完成準備，再一次詢問。
缺用途／模板來源只問必要輸入，不猜產品架構。

收到核准後只 stage 明列 paths，驗 staged name/status 與完整 diff 逐 byte 符合核准內容；首顆 commit
在 feature branch，使用 target convention。取得 full SHA，驗證 root commit／tree 只有核准檔案、
沒有父 commit 或未核准 blob。Intended-default local ref 必須不存在；以 exact SHA 建它，不切 HEAD，
不覆寫 existing ref。Hook 若改內容／加檔則停止，不把變動當已核准。

## 一次 push 與 postconditions

Push 前重驗所有 remote heads/tags、provider default／creation policy 與唯一 push destination，
不能沿用準備前 snapshot。工具 cwd 綁 target root；明確 remote、full SHA refspec，以 create-only
lease 防最後查詢後 default 被建立。Expected value 空白表示 ref 必須不存在：

```text
git push --force-with-lease=refs/heads/<default>: <remote> <reviewed-full-SHA>:refs/heads/<default>
```

只可建立新 ref，不可普通 force／裸 push／多 ref／改推 feature。Lease 不鎖整個 remote；別的 branch
若同時建立導致 actual default 不同，報衝突，不改 metadata。只執行一次 push；失败／timeout 查 exact
ref/SHA 與 default，baseline 已存在不再初始化，未知／未完成結果不自行重送或換命令。

成功後驗 default SHA 與 provider actual default，重跑一般政策盤點；核對 HEAD 仍在 feature、
tree/index 與核准範圍。報 baseline、SHA、未納管項及後續產品走 PR；不把尚無產品 CI 當完整產品驗收。
文件基線階段的產品／完整文件待補項列為下一階段要求，不因核准 allowlist 未包含它們而報初始化 FAIL。
Remote 有內容後例外失效，換 session／再次叫 skill 不恢復。必要新操作另有明確授權。
