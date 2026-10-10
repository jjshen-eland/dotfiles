#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034,SC2153
    cat > "$TMP/gh-open" <<'STUB'
#!/usr/bin/env bash
case "$*" in
    *nameWithOwner*) echo "acme/widget" ;;
    *viewerPermission*) echo "READ" ;;
    *"api repos/acme/widget --jq .default_branch"*) echo "main" ;;
    *"/protection"*) echo "gh: Branch not protected (HTTP 404)"; exit 1 ;;
    *"rules/branches"*) echo '[]' ;;
esac
STUB
    chmod +x "$TMP/gh-open"
    git init --bare -q -b main "$TMP/sb-origin.git"
    git init -q -b main "$TMP/sb-seed"
    (cd "$TMP/sb-seed" \
        && echo hi > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
        && git remote add origin "$TMP/sb-origin.git" && git push -qu origin main)

echo "▶ 14. codex-runtime-hygiene.sh 孤兒偵測 / 誤殺防護 / exit 契約"
CH_SCRIPT="$ROOT/claude/skills/deep-review/scripts/codex-runtime-hygiene.sh"
CH_STATE="$TMP/ch-state"
# 假「現行 codex」：讓 CURRENT_CODEX 判定不依賴這台機器有沒有裝 codex。
# 注意：假 binary 用 sleep 迴圈（不可單發長 sleep——孫進程會繼承 stdout pipe 卡住整個測試管線，
# 且 pkill 殺不到裸 `sleep N` 的 argv）；spawn 一律 >/dev/null 斷開 pipe 繼承。
mkdir -p "$TMP/ch-current-bin" "$TMP/ch-orphan-bin"
printf '#!/bin/sh\nwhile :; do sleep 5; done\n' > "$TMP/ch-current-bin/codex"
printf '#!/bin/sh\nwhile :; do sleep 5; done\n' > "$TMP/ch-orphan-bin/codex"
chmod +x "$TMP/ch-current-bin/codex" "$TMP/ch-orphan-bin/codex"
CH_ENV=(env "PATH=$TMP/ch-current-bin:$PATH" \
    "CODEX_HYGIENE_STATE_DIR=$CH_STATE" \
    "CODEX_HYGIENE_BROKER_PATTERN=ch-fake-broker-serve")
ch_pids_cleanup() { pkill -f ch-fake-broker-serve 2>/dev/null; pkill -f "$TMP/ch-orphan-bin/codex" 2>/dev/null; return 0; }
# source-only 掛鉤載入函式後呼叫 broker_actively_working（子 shell 隔離 env 與 set -uo，變更不外洩——刻意）。
# source 前必須 set -- 清位置參數：sourced script 的 $1 會繼承本函式參數，污染其 MODE 判定
# shellcheck disable=SC1090,SC2030,SC2031
ch_actively_working() {
    (export CODEX_HYGIENE_SOURCED=1 CODEX_HYGIENE_STATE_DIR="$CH_STATE"
     ch_bpid="$1"; set --
     . "$CH_SCRIPT"; broker_actively_working "$ch_bpid")
}

# --- broker_actively_working 函式級測試（source-only 掛鉤）---
# S1 迴歸：plugin 的 jobs 陣列「新的在前」（unshift + updatedAt 降冪 prune）。
# jobs[0]=running＋新鮮 log、jobs[尾]=completed → 必須判現役（rc=0）；讀錯端（.jobs[-1]）會誤殺。
mkdir -p "$CH_STATE/.myrepo-aaa111"   # dot 開頭目錄：glob 會漏、find 不會
touch "$TMP/ch-job.log"
printf '{"pid":4242,"sessionDir":"none"}\n' > "$CH_STATE/.myrepo-aaa111/broker.json"
printf '{"jobs":[{"status":"running","logFile":"%s"},{"status":"completed","logFile":"%s"}]}\n' \
    "$TMP/ch-job.log" "$TMP/ch-job.log" > "$CH_STATE/.myrepo-aaa111/state.json"
rc=0
ch_actively_working 4242 || rc=$?
assert_rc "S1：jobs[0]=running＋新鮮 log → 現役不殺（rc=0）" 0 "$rc"

# 全 completed（無 active job）→ 非現役可清（rc=1）
printf '{"jobs":[{"status":"completed","logFile":"%s"}]}\n' "$TMP/ch-job.log" \
    > "$CH_STATE/.myrepo-aaa111/state.json"
rc=0
ch_actively_working 4242 || rc=$?
assert_rc "全 completed → 非現役（rc=1）" 1 "$rc"

# active job 但 log 停滯（>15 分）→ 非現役（rc=1）
touch -t 202601011200 "$TMP/ch-job.log"
printf '{"jobs":[{"status":"running","logFile":"%s"}]}\n' "$TMP/ch-job.log" \
    > "$CH_STATE/.myrepo-aaa111/state.json"
rc=0
ch_actively_working 4242 || rc=$?
assert_rc "active 但 log 停滯 → 可清（rc=1）" 1 "$rc"
rm -f "$CH_STATE/.myrepo-aaa111"/broker.json "$CH_STATE/.myrepo-aaa111"/state.json

# --- 端到端：split-brain 現役 SKIP（check exit 3）→ 轉可清（exit 1）→ clean 收割（exit 0）---
# 假 broker：argv 帶測試 pattern，子進程跑「非現行 codex」絕對路徑 binary（= split-brain）
bash -c ": ch-fake-broker-serve; \"$TMP/ch-orphan-bin/codex\" & wait" >/dev/null 2>&1 &
CH_BPID=$!
sleep 0.3   # 等子進程 spawn
touch "$TMP/ch-job.log"
printf '{"pid":%s,"sessionDir":"%s"}\n' "$CH_BPID" "$TMP/ch-sock-cxc-none" > "$CH_STATE/.myrepo-aaa111/broker.json"
printf '{"jobs":[{"status":"running","logFile":"%s"}]}\n' "$TMP/ch-job.log" > "$CH_STATE/.myrepo-aaa111/state.json"
"${CH_ENV[@]}" "$CH_SCRIPT" check >/dev/null 2>&1
assert_rc "e2e：split-brain＋現役 job → check exit 3（SKIP 不殺）" 3 $?
kill -0 "$CH_BPID" 2>/dev/null
assert_rc "e2e：check 後假 broker 仍存活" 0 $?

# job 轉 completed → 可清孤兒（check exit 1）→ clean 收割並複驗乾淨（exit 0）
printf '{"jobs":[{"status":"completed","logFile":"%s"}]}\n' "$TMP/ch-job.log" > "$CH_STATE/.myrepo-aaa111/state.json"
"${CH_ENV[@]}" "$CH_SCRIPT" check >/dev/null 2>&1
assert_rc "e2e：job 已完 → check exit 1（可清孤兒）" 1 $?
"${CH_ENV[@]}" "$CH_SCRIPT" clean >/dev/null 2>&1
assert_rc "e2e：clean 收割孤兒＋複驗 → exit 0" 0 $?
sleep 0.3
if ! kill -0 "$CH_BPID" 2>/dev/null && ! pgrep -f "$TMP/ch-orphan-bin/codex" >/dev/null 2>&1; then
    ok "e2e：孤兒 broker 與其 app-server 子進程皆被收"
else bad "e2e：孤兒進程未收乾淨"; ch_pids_cleanup; fi
if [ ! -e "$CH_STATE/.myrepo-aaa111/broker.json" ]; then ok "e2e：孤兒 broker.json 已移除"; else bad "e2e：broker.json 未移除"; fi

# --- stale broker.json（pid 已死）＋ rm -rf 前綴防護 ---
mkdir -p "$CH_STATE/normal-bbb222" "$TMP/ch-sock/cxc-good" "$TMP/ch-sock/important-data"
printf '{"pid":99999999,"sessionDir":"%s"}\n' "$TMP/ch-sock/cxc-good" > "$CH_STATE/.myrepo-aaa111/broker.json"
printf '{"pid":null,"sessionDir":"%s"}\n' "$TMP/ch-sock/important-data" > "$CH_STATE/normal-bbb222/broker.json"
"${CH_ENV[@]}" "$CH_SCRIPT" check >/dev/null 2>&1
assert_rc "stale json（含 dot 目錄）→ check exit 1" 1 $?
"${CH_ENV[@]}" "$CH_SCRIPT" clean >/dev/null 2>&1
assert_rc "stale json clean → exit 0" 0 $?
if [ ! -e "$CH_STATE/.myrepo-aaa111/broker.json" ] && [ ! -e "$CH_STATE/normal-bbb222/broker.json" ]; then
    ok "stale broker.json 兩目錄（含 dot）皆清除"
else bad "stale broker.json 未清乾淨（dot 目錄漏掃？）"; fi
if [ ! -d "$TMP/ch-sock/cxc-good" ]; then ok "cxc- sessionDir 已移除"; else bad "cxc- sessionDir 未移除"; fi
if [ -d "$TMP/ch-sock/important-data" ]; then ok "非 cxc- sessionDir 保留（rm -rf 前綴防護）"; else bad "非 cxc- 路徑被誤刪"; fi
"${CH_ENV[@]}" "$CH_SCRIPT" check >/dev/null 2>&1
assert_rc "清理後 → check exit 0（乾淨）" 0 $?
"${CH_ENV[@]}" "$CH_SCRIPT" bogus >/dev/null 2>&1
assert_rc "未知模式 → exit 2" 2 $?
ch_pids_cleanup


echo "▶ 17. codex-exec-review.sh（deep-review skill script）exit 契約與 job 產物"
CER="$ROOT/claude/skills/deep-review/scripts/codex-exec-review.sh"
cer_base="$TMP/cer"
mkdir -p "$cer_base/bin" "$cer_base/jobs"

# 測試用 repo（兩個 commit，供 range 解析）
cer_repo="$cer_base/repo"
mkdir -p "$cer_repo"
(cd "$cer_repo" && git init -q && git config user.email t@t && git config user.name t \
    && echo one > a.txt && git add -A && git commit -qm first \
    && echo two >> a.txt && git commit -qam second) >/dev/null 2>&1
cer_range="$(cd "$cer_repo" && git rev-parse HEAD~1)..HEAD"

# codex stub：可切換「寫報告」/「不寫報告」，並吐出帶 session id 的 events。
# **模擬 clap 的 argv 拒絕行為**：`codex exec` 與 `codex exec resume` 是不同 subcommand、
# 旗標集合不同（resume 無 --color / -s / -C）。stub 若照單全收，旗標層級的契約違反在測試裡
# 等於不存在——2026-07-20 R1 審查即因此讓 resume 三處介面不符一路綠燈進 commit。
# NEVER loosen this stub to accept unknown flags.
cer_make_stub() {   # cer_make_stub <write_report:yes|no> [id_field]
    cat > "$cer_base/bin/codex" <<EOF
#!/usr/bin/env bash
# 落檔供斷言：實際 argv 與執行時的 cwd
printf '%s\n' "\$@" > "\${CODEX_STUB_ARGV:-/dev/null}"
pwd > "\${CODEX_STUB_CWD:-/dev/null}"
{
    printf 'TMPDIR=%s\n' "\${TMPDIR:-}"
    printf 'UV_CACHE_DIR=%s\n' "\${UV_CACHE_DIR:-}"
    printf 'PYTEST_ADDOPTS=%s\n' "\${PYTEST_ADDOPTS:-}"
} > "\${CODEX_STUB_ENV:-/dev/null}"

[ "\$1" = "exec" ] || { echo "error: unexpected subcommand '\$1'" >&2; exit 2; }
shift
mode="exec"
if [ "\${1:-}" = "resume" ]; then mode="resume"; shift; [ -n "\${1:-}" ] && case "\$1" in -*) ;; *) shift ;; esac; fi

out=""
while [ \$# -gt 0 ]; do
    case "\$1" in
        --json|--ephemeral|--skip-git-repo-check|--ignore-user-config|--strict-config) shift ;;
        -o|--output-last-message) out="\${2:-}"; shift 2 ;;
        -m|--model|-c|--config|--output-schema) shift 2 ;;
        --color|-s|--sandbox|-C|--cd)
            # 僅 exec 合法；resume 遇到即如 clap 般拒絕
            if [ "\$mode" = "resume" ]; then
                echo "error: unexpected argument '\$1' found" >&2; exit 2
            fi
            shift 2 ;;
        -*) echo "error: unexpected argument '\$1' found" >&2; exit 2 ;;
        *) shift ;;   # prompt 位置引數
    esac
done

echo '{"${2:-session_id}":"sess-fixture-1","type":"session_meta"}'
[ "$1" = "yes" ] && [ -n "\$out" ] && printf 'CODEX 報告\n' > "\$out"
exit 0
EOF
    chmod +x "$cer_base/bin/codex"
}
cer_run() { PATH="$cer_base/bin:$PATH" CODEX_EXEC_REVIEW_DIR="$cer_base/jobs" bash "$CER" "$@"; }

# (1) 報告產出 → exit 0 + job 產物齊全 + session id 取出
# 斷言一律打**真實 argv**（stub 落檔），不打 $job/cmd——後者是重建字串，
# 真實呼叫若漂移（如掉了 permission profile）它照樣長對，等於守空。
cer_make_stub yes
cer_argv_run="$TMP/cer-run.argv"
cer_env_run="$TMP/cer-run.env"
cer_out="$(CODEX_STUB_ARGV="$cer_argv_run" CODEX_STUB_ENV="$cer_env_run" cer_run run --repo "$cer_repo" --range "$cer_range" --round C1 2>/dev/null)"
assert_rc "run 產出報告 → exit 0" 0 $?
cer_job="$(printf '%s\n' "$cer_out" | sed -n 's/^job-dir: //p' | head -1)"
if [ -n "$cer_job" ] && [ -d "$cer_job" ]; then ok "run 第一行印出 job-dir"; else bad "run 未印出可用的 job-dir"; fi
cer_job_real="$(cd "$cer_job" && pwd -P)"
cer_missing=""
for f in cmd meta events.jsonl report.md session-id exit-code; do
    [ -f "$cer_job/$f" ] || cer_missing="$cer_missing $f"
done
assert_eq "job 產物齊全" "" "$cer_missing"
assert_eq "session id 自 events 取出" "sess-fixture-1" "$(cat "$cer_job/session-id")"
if grep -qxF "Run your repo-review skill on $cer_repo for $cer_range. 繁體中文." "$cer_argv_run"; then
    ok "送出的 prompt 為一行協議原文（真實 argv）"
else bad "prompt 偏離一行協議原文"; fi
if grep -qxF -- "--ignore-user-config" "$cer_argv_run" \
    && grep -qxF -- "--strict-config" "$cer_argv_run" \
    && grep -qxF 'default_permissions="repo_review_temp"' "$cer_argv_run" \
    && grep -qxF 'permissions.repo_review_temp.extends=":read-only"' "$cer_argv_run" \
    && grep -qxF 'permissions.repo_review_temp.filesystem={":tmpdir"="write"}' "$cer_argv_run"; then
    ok "run 以嚴格 permission profile 保持 repo 唯讀、只開 tmp 寫入"
else bad "run 未帶 repo 唯讀 + tmp 可寫的嚴格 permission profile"; fi
if grep -qxF "TMPDIR=$cer_job_real/tmp" "$cer_env_run" \
    && grep -qxF "UV_CACHE_DIR=$cer_job_real/tmp/uv" "$cer_env_run" \
    && grep -qF "$cer_job_real/tmp/pytest" "$cer_env_run"; then
    ok "run 將 tmp、uv、pytest cache 導向 job 暫存目錄"
else bad "run 未完整導向測試暫存與 cache：$(tr '\n' ' ' < "$cer_env_run")"; fi
if grep -qxF -- "-C" "$cer_argv_run" && grep -qxF "$cer_repo" "$cer_argv_run"; then
    ok "run 以 -C 指向受審 repo（真實 argv）"
else bad "run 未以 -C 指向受審 repo"; fi
if grep -qxF -- "--json" "$cer_argv_run"; then ok "run 帶 --json（events 可解析）"; else bad "run 未帶 --json"; fi
# $job/cmd 仍須忠實反映真實呼叫（同一 argv 陣列衍生），供事後複製重跑
if grep -qF -- 'default_permissions' "$cer_job/cmd" && grep -qF -- 'repo_review_temp' "$cer_job/cmd"; then
    ok "cmd 記錄與真實呼叫同源"
else bad "cmd 記錄與真實呼叫脫節"; fi

# (2) 進程結束但報告空 → exit 4（升級 resume），且 thread_id 欄位也能取到 session id
cer_make_stub no thread_id
cer_out="$(cer_run run --repo "$cer_repo" --range "$cer_range" --round C1 2>/dev/null)"
assert_rc "run 報告空 → exit 4" 4 $?
cer_job2="$(printf '%s\n' "$cer_out" | sed -n 's/^job-dir: //p' | head -1)"
cer_job2_real="$(cd "$cer_job2" && pwd -P)"
assert_eq "session id 亦支援 thread_id 欄位" "sess-fixture-1" "$(cat "$cer_job2/session-id")"
# job 目錄唯一性（mktemp）：同秒兩次 run 若共用目錄，會把上一輪的 report.md 當本輪產出 → 假成功
if [ "$cer_job" != "$cer_job2" ]; then ok "同秒兩次 run 的 job 目錄不碰撞"; else bad "job 目錄碰撞（會誤報上輪報告）"; fi

# (3) resume：用記錄的 session id，救不回 → 4；救得回 → 0
cer_run resume --job-dir "$cer_job2" >/dev/null 2>&1
assert_rc "resume 仍無產出 → exit 4" 4 $?
cer_make_stub yes
cer_argv="$TMP/cer-resume.argv"
cer_cwd="$TMP/cer-resume.cwd"
cer_env_resume="$TMP/cer-resume.env"
cer_out="$(CODEX_STUB_ARGV="$cer_argv" CODEX_STUB_CWD="$cer_cwd" CODEX_STUB_ENV="$cer_env_resume" cer_run resume --job-dir "$cer_job2" 2>/dev/null)"
assert_rc "resume 救回報告 → exit 0" 0 $?
if grep -qF "resume session: sess-fixture-1" <<< "$cer_out"; then
    ok "resume 沿用 job 記錄的 session id"
else bad "resume 未使用記錄的 session id"; fi

# resume 的 CLI 介面契約（對照真實 binary：resume 無 --color / -s / -C）
if grep -qxF -- "--color" "$cer_argv"; then bad "resume 帶了 --color（真實 binary 會 clap 拒絕）"; else ok "resume 未帶 --color"; fi
if grep -qxF -- "-s" "$cer_argv"; then bad "resume 帶了 -s（真實 binary 會 clap 拒絕）"; else ok "resume 未帶 -s"; fi
if grep -qxF -- "-C" "$cer_argv"; then bad "resume 帶了 -C（真實 binary 會 clap 拒絕）"; else ok "resume 未帶 -C"; fi
# session id 也要打真實 argv：只驗腳本自印的 "resume session:" 的話，argv 掉了 sid 仍會全綠
# （真實 binary 缺 SESSION_ID 且無 --last 會失敗）
if grep -qxF "sess-fixture-1" "$cer_argv"; then ok "resume 的 session id 出現在真實 argv"; else bad "resume 未把 session id 傳給 codex"; fi
# resume 無 -s，仍須顯式套用同一 permission profile（否則落回 config.toml 的 danger-full-access）
if grep -qxF -- "--ignore-user-config" "$cer_argv" \
    && grep -qxF -- "--strict-config" "$cer_argv" \
    && grep -qxF 'default_permissions="repo_review_temp"' "$cer_argv" \
    && grep -qxF 'permissions.repo_review_temp.extends=":read-only"' "$cer_argv" \
    && grep -qxF 'permissions.repo_review_temp.filesystem={":tmpdir"="write"}' "$cer_argv"; then
    ok "resume 維持 repo 唯讀 + tmp 可寫的嚴格 permission profile"
else bad "resume 未約束 permission profile（可能落回 danger-full-access）"; fi
if grep -qxF "TMPDIR=$cer_job2_real/tmp" "$cer_env_resume" \
    && grep -qxF "UV_CACHE_DIR=$cer_job2_real/tmp/uv" "$cer_env_resume" \
    && grep -qF "$cer_job2_real/tmp/pytest" "$cer_env_resume"; then
    ok "resume 沿用 job 暫存與 cache 目錄"
else bad "resume 未完整導向測試暫存與 cache"; fi
# resume 不支援 -C，須自行 cd 到受審 repo，否則繼承呼叫者 cwd
assert_eq "resume 在受審 repo 的工作目錄下執行" "$(cd "$cer_repo" && pwd -P)" "$(cd "$(cat "$cer_cwd")" && pwd -P)"
# 失敗現場可見（B1）
if [ -f "$cer_job2/cmd-resume" ]; then ok "resume 記錄實際指令（cmd-resume）"; else bad "resume 未記錄 cmd-resume"; fi
cer_status_r="$(cer_run status --job-dir "$cer_job2" 2>/dev/null)"
if grep -q '^codex-exit-resume=' <<< "$cer_status_r"; then
    ok "status 印出 resume 的 exit code"
else bad "status 未涵蓋 resume（失敗原因看不到）"; fi

# (4) 環境/引數錯誤 → exit 5
cer_make_stub yes
cer_run run --repo "$cer_base/nonexistent" --range "$cer_range" --round C1 >/dev/null 2>&1
assert_rc "repo 不存在 → exit 5" 5 $?
cer_run run --repo "$cer_base" --range "$cer_range" --round C1 >/dev/null 2>&1
assert_rc "非 git repo → exit 5" 5 $?
cer_run run --repo "$cer_repo" --range "HEAD..nosuchref" --round C1 >/dev/null 2>&1
assert_rc "range head 端無法解析 → exit 5" 5 $?
cer_run run --repo "$cer_repo" --range "noDots" --round C1 >/dev/null 2>&1
assert_rc "range 缺 .. → exit 5" 5 $?
CODEX_EXEC_REVIEW_DIR="$cer_base/jobs" PATH=/usr/bin:/bin bash "$CER" run --repo "$cer_repo" --range "$cer_range" --round C1 >/dev/null 2>&1
assert_rc "codex 不在 PATH → exit 5" 5 $?
cer_inside_argv="$TMP/cer-inside-repo.argv"
CODEX_STUB_ARGV="$cer_inside_argv" CODEX_EXEC_REVIEW_DIR="$cer_repo/.review-jobs" \
    PATH="$cer_base/bin:$PATH" bash "$CER" run --repo "$cer_repo" --range "$cer_range" --round C1 >/dev/null 2>&1
assert_rc "reviewer 暫存根位於受審 repo 內 → exit 5" 5 $?
if [ ! -s "$cer_inside_argv" ]; then
    ok "repo 內暫存根在啟動 codex 前即被拒"
else bad "repo 內暫存根仍啟動了 codex（會在唯讀 repo 打寫入洞）"; fi
rm -rf "$cer_repo/.review-jobs"

# (5) baseline 模式：base 端非 rev（∅）只警告不阻擋——不可退化成 exit 5
cer_make_stub yes
cer_err="$TMP/cer-baseline.err"
cer_run run --repo "$cer_repo" --range "∅..HEAD" --round C1 >/dev/null 2>"$cer_err"
assert_rc "baseline ∅ base → 不判環境錯誤" 0 $?
if grep -qF "baseline 模式" "$cer_err"; then ok "baseline base 端有告知"; else bad "baseline base 端未告知"; fi

# (6) 用法錯誤 → exit 2
cer_run run --repo "$cer_repo" --range "$cer_range" >/dev/null 2>&1
assert_rc "缺 --round → exit 2" 2 $?
cer_run bogus >/dev/null 2>&1
assert_rc "未知子指令 → exit 2" 2 $?
# --round 直接進 mktemp 樣板：含路徑分隔字元須在此攔下，否則錯誤訊息會誤指「無法建立 job 目錄」
cer_run run --repo "$cer_repo" --range "$cer_range" --round "C1/x" >/dev/null 2>&1
assert_rc "--round 含 / → exit 2" 2 $?
# range 多組 .. 會讓中段被靜默吞掉；三點 range（branch diff）則必須照常可用
cer_run run --repo "$cer_repo" --range "a..b..c" --round C1 >/dev/null 2>&1
assert_rc "range 多組 .. → exit 5" 5 $?
# 三點 range 必須**拒絕**：下游 shared review-scope helper 明確拒絕語意不唯一的 three-dot。
# wrapper 若放行，codex 可能只把錯誤寫進 report.md，而報告非空會被誤判為成功；stub 不會
# 真的跑 helper，故這條仍須靠斷言釘死。
cer_run run --repo "$cer_repo" --range "HEAD...HEAD" --round C1 >/dev/null 2>&1
assert_rc "三點 range → exit 5（與下游 repo-review 契約一致）" 5 $?
# base 端只放行明確的 baseline 表示法：拼錯的 base 若只警告就放行，會產出「成功但其實
# 什麼都沒審」的報告（codex 把無法 diff 的錯誤寫進 report.md，腳本照樣回 0）
cer_run run --repo "$cer_repo" --range "maim..HEAD" --round C1 >/dev/null 2>&1
assert_rc "拼錯的 base → exit 5（不得只警告放行）" 5 $?
cer_argv_bl="$TMP/cer-baseline.argv"
CODEX_STUB_ARGV="$cer_argv_bl" cer_run run --repo "$cer_repo" --range "∅..HEAD" --round C1 >/dev/null 2>&1
assert_rc "baseline ∅ base → 照常放行" 0 $?
# ∅ 是報告模板的顯示寫法、不是 object name → 必須正規化成 shared helper 支援的 empty-tree hash
if grep -q '4b825dc642cb6eb9a060e54bf8d69288fbee4904\.\.HEAD' "$cer_argv_bl"; then
    ok "∅ 已正規化為 empty-tree hash 才送給 codex"
else bad "∅ 原樣送出——下游會回 cannot resolve range base"; fi
cer_run run --repo "$cer_repo" --range "4b825dc642cb6eb9a060e54bf8d69288fbee4904..HEAD" --round C1 >/dev/null 2>&1
assert_rc "baseline empty-tree hash → 照常放行" 0 $?
cer_run >/dev/null 2>&1
assert_rc "無引數 → exit 2" 2 $?

# (7) status 可讀出關鍵欄位
cer_status="$(cer_run status --job-dir "$cer_job" 2>/dev/null)"
assert_rc "status → exit 0" 0 $?
if grep -q '^codex-exit=' <<< "$cer_status"; then ok "status 印出 codex-exit"; else bad "status 缺 codex-exit"; fi
if grep -q '^report=.*bytes' <<< "$cer_status"; then ok "status 印出報告大小"; else bad "status 缺報告資訊"; fi

# (8) 錯誤分支：status / resume 的前置檢查
cer_run status --job-dir "$cer_base/no-such-job" >/dev/null 2>&1
assert_rc "status 對不存在的 job dir → exit 5" 5 $?
cer_run status >/dev/null 2>&1
assert_rc "status 缺 --job-dir → exit 2" 2 $?
# 「此 job 不可續」須回 4（往下一階跑 fresh run），不可回 5——5 的契約是「停、不重試」，
# 會讓呼叫端跳過階梯第 2 步並輸出誤導性的環境診斷（codex 明明就在 PATH）
cer_bare="$cer_base/jobs/bare"; mkdir -p "$cer_bare"
cer_run resume --job-dir "$cer_bare" >/dev/null 2>&1
assert_rc "resume 無 session-id → exit 4（非 5）" 4 $?
printf 'sess-x\n' > "$cer_bare/session-id"
cer_run resume --job-dir "$cer_bare" >/dev/null 2>&1
assert_rc "resume 的 meta 無可用 repo → exit 4（非 5）" 4 $?
# 真環境錯誤才回 5
cer_run resume --job-dir "$cer_base/no-such-job" >/dev/null 2>&1
assert_rc "resume 對不存在的 job dir → exit 5" 5 $?
# cmd-resume 需可直接貼回 shell 執行（&& 不可被 %q 轉義）
if grep -q ' && ' "$cer_job2/cmd-resume" && ! grep -q '\\&\\&' "$cer_job2/cmd-resume"; then
    ok "cmd-resume 可直接複製重跑（&& 未被轉義）"
else bad "cmd-resume 的 && 被轉義，貼回 shell 不能跑"; fi

# (9) 路徑含空白（job root 與 repo 皆是）
cer_sp="$cer_base/with space"
mkdir -p "$cer_sp/repo root"
(cd "$cer_sp/repo root" && git init -q && git config user.email t@t && git config user.name t \
    && echo x > f.txt && git add -A && git commit -qm one) >/dev/null 2>&1
cer_out="$(PATH="$cer_base/bin:$PATH" CODEX_EXEC_REVIEW_DIR="$cer_sp/jobs" \
    bash "$CER" run --repo "$cer_sp/repo root" --range "HEAD..HEAD" --round C1 2>/dev/null)"
assert_rc "路徑含空白 → exit 0" 0 $?
cer_job_sp="$(printf '%s\n' "$cer_out" | sed -n 's/^job-dir: //p' | head -1)"
if [ -s "$cer_job_sp/report.md" ]; then ok "路徑含空白 → 報告正確落檔"; else bad "路徑含空白 → 報告未落檔"; fi


echo "▶ 19. review-anchor.sh（deep-review skill script）錨點生命週期 / squash-cmd / codex-next"
RA_SCRIPT="$ROOT/claude/skills/deep-review/scripts/review-anchor.sh"

# fixture：bare origin + clone，main 已 push；feature branch 領先 2 commit
git init --bare -q -b main "$TMP/ra-origin.git"
git init -q -b main "$TMP/ra-work"
(cd "$TMP/ra-work" \
    && echo a > f.txt && "${GITC[@]}" add f.txt && "${GITC[@]}" commit -qm init \
    && git remote add origin "$TMP/ra-origin.git" && git push -qu origin main \
    && git switch -qc feat/x \
    && echo b > f.txt && "${GITC[@]}" commit -qam "feat: x" \
    && echo c > f.txt && "${GITC[@]}" commit -qam "fix: R1 review fixes")

# show 無 anchor → exit 1（STOP）
"$RA_SCRIPT" show --repo "$TMP/ra-work" >/dev/null 2>&1
assert_rc "show 無 anchor → exit 1（STOP）" 1 $?

# record branch-diff → base = merge-base（腳本自解析，model 不心算）
"$RA_SCRIPT" record --repo "$TMP/ra-work" --mode branch-diff --base origin/main >/dev/null
assert_rc "record branch-diff → exit 0" 0 $?
ra_mb="$(git -C "$TMP/ra-work" merge-base origin/main HEAD)"
ra_anchor="$(git -C "$TMP/ra-work" rev-parse --absolute-git-dir)/deep-review/anchor"
if [ -f "$ra_anchor" ] && grep -qxF "base=$ra_mb" "$ra_anchor"; then ok "anchor 檔落地且 base=merge-base"; else bad "anchor base 錯誤"; fi

# squash-cmd happy path → 精確整行（固定 hash）+ commit 清單
# squash base ≠ anchor base：base..HEAD 由新到舊掃，跳過 review 樣式 commit，停在第一顆
# 真語意 commit（此處 feat: x）——review fix 才壓，使用者的語意 commit 原樣留下。
ra_feat_x="$(git -C "$TMP/ra-work" rev-parse HEAD~1)"
out="$("$RA_SCRIPT" squash-cmd --repo "$TMP/ra-work")"
assert_rc "squash-cmd happy path → exit 0" 0 $?
if grep -qxF "squash-cmd: git -C '$TMP/ra-work' reset --soft $ra_feat_x" <<< "$out"; then ok "squash-cmd 停在語意 commit（不壓既有 feat）"; else bad "squash-cmd 指令錯誤（squash base 未避開既有語意 commit）"; fi
if grep -q "fix: R1 review fixes" <<< "$out"; then ok "squash-range 列出 commit"; else bad "squash-range 清單缺失"; fi
if grep -q "^squash-preserve: 1 顆" <<< "$out" && grep -q "feat: x" <<< "$out"; then ok "squash-preserve 列出保留的既有 commit"; else bad "squash-preserve 缺失或未列保留 commit"; fi

# record 無條件覆蓋（working-tree → base=HEAD）
ra_head="$(git -C "$TMP/ra-work" rev-parse HEAD)"
"$RA_SCRIPT" record --repo "$TMP/ra-work" --mode working-tree >/dev/null
if grep -qxF "base=$ra_head" "$ra_anchor"; then ok "record 二次呼叫無條件覆蓋"; else bad "record 未覆蓋"; fi

# range mode：下界解析 / 三點拒絕 / 壞 ref
ra_first="$(git -C "$TMP/ra-work" rev-parse main)"
"$RA_SCRIPT" record --repo "$TMP/ra-work" --mode range --range "$ra_first..HEAD" >/dev/null
assert_rc "record range → exit 0" 0 $?
if grep -qxF "base=$ra_first" "$ra_anchor"; then ok "range 下界解析正確"; else bad "range 下界錯誤"; fi
"$RA_SCRIPT" record --repo "$TMP/ra-work" --mode range --range "main...HEAD" >/dev/null 2>&1
assert_rc "三點 range → exit 2" 2 $?
"$RA_SCRIPT" record --repo "$TMP/ra-work" --mode range --range "nope..HEAD" >/dev/null 2>&1
assert_rc "壞 ref → exit 1" 1 $?

# anchor hash 不存在（GC/rebase 模擬）→ STOP
printf 'base=%s\nmode=branch-diff\nbranch=feat/x\nrecorded=0\n' "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef" > "$ra_anchor"
"$RA_SCRIPT" squash-cmd --repo "$TMP/ra-work" >/dev/null 2>&1
assert_rc "anchor hash 已不存在 → exit 1（STOP）" 1 $?

# anchor 非 HEAD 祖先（換到不含 anchor 的 branch）→ STOP
"$RA_SCRIPT" record --repo "$TMP/ra-work" --mode working-tree >/dev/null
(cd "$TMP/ra-work" && git switch -qc other main)
"$RA_SCRIPT" squash-cmd --repo "$TMP/ra-work" >/dev/null 2>&1
assert_rc "anchor 非 HEAD 祖先 → exit 1（STOP）" 1 $?
(cd "$TMP/ra-work" && git switch -q feat/x && git branch -qD other)

# record 在 main、之後 switch -c → squash-cmd 照常（stale 判 ancestry、非 branch 名）
git clone -q "$TMP/ra-origin.git" "$TMP/ra-bf"
"$RA_SCRIPT" record --repo "$TMP/ra-bf" --mode working-tree >/dev/null
(cd "$TMP/ra-bf" && git switch -qc feat/z && echo z > z.txt && "${GITC[@]}" add z.txt && "${GITC[@]}" commit -qm "fix: z")
"$RA_SCRIPT" squash-cmd --repo "$TMP/ra-bf" >/dev/null
assert_rc "record→switch -c 後 squash-cmd 照常 → exit 0" 0 $?

# 空 range → WARNING、exit 0（reset 到 HEAD 無害）
"$RA_SCRIPT" record --repo "$TMP/ra-work" --mode working-tree >/dev/null
out="$("$RA_SCRIPT" squash-cmd --repo "$TMP/ra-work")"
assert_rc "無 commit 可 squash → exit 0" 0 $?
if grep -q "WARNING" <<< "$out"; then ok "空 range → WARNING"; else bad "空 range 未警告"; fi

# codex-next：C1 → 冪等 → C2 增量 → --full → C4 上限
"$RA_SCRIPT" record --repo "$TMP/ra-work" --mode branch-diff --base origin/main >/dev/null
ra_h1="$(git -C "$TMP/ra-work" rev-parse HEAD)"
out="$("$RA_SCRIPT" codex-next --repo "$TMP/ra-work")"
assert_rc "codex-next C1 → exit 0" 0 $?
if grep -q "codex-round: C1" <<< "$out" && grep -qxF "codex-range: $ra_mb..$ra_h1" <<< "$out"; then ok "C1 range = anchor-base..HEAD"; else bad "C1 range 錯誤"; fi
if grep -qF "codex-cmd: ~/.claude/skills/deep-review/scripts/codex-exec-review.sh run --repo '$TMP/ra-work' --range $ra_mb..$ra_h1 --round C1" <<< "$out"; then ok "codex-cmd 整行照抄可執行"; else bad "codex-cmd 錯誤"; fi
out="$("$RA_SCRIPT" codex-next --repo "$TMP/ra-work")"
assert_rc "同 HEAD 再呼叫 → exit 0" 0 $?
if grep -q "codex-round: C1" <<< "$out"; then ok "同 HEAD 冪等（round 不誤增）"; else bad "冪等失敗"; fi
(cd "$TMP/ra-work" && echo d > f.txt && "${GITC[@]}" commit -qam "fix: codex C1 fixes")
ra_h2="$(git -C "$TMP/ra-work" rev-parse HEAD)"
out="$("$RA_SCRIPT" codex-next --repo "$TMP/ra-work")"
if grep -q "codex-round: C2" <<< "$out" && grep -qxF "codex-range: $ra_h1..$ra_h2" <<< "$out"; then ok "C2 增量 range = 上輪 HEAD..HEAD"; else bad "C2 range 錯誤"; fi
(cd "$TMP/ra-work" && echo e > f.txt && "${GITC[@]}" commit -qam "fix: codex C2 fixes")
ra_h3="$(git -C "$TMP/ra-work" rev-parse HEAD)"
out="$("$RA_SCRIPT" codex-next --repo "$TMP/ra-work" --full)"
if grep -q "codex-round: C3" <<< "$out" && grep -qxF "codex-range: $ra_mb..$ra_h3" <<< "$out"; then ok "--full → C1 scope、round 照推"; else bad "--full 錯誤"; fi
(cd "$TMP/ra-work" && echo f2 > f.txt && "${GITC[@]}" commit -qam "fix: codex C3 fixes")
"$RA_SCRIPT" codex-next --repo "$TMP/ra-work" >/dev/null 2>&1
assert_rc "超過 C3 上限 → exit 1（STOP）" 1 $?
if grep -qxF "codex_round=3" "$ra_anchor"; then ok "超上限 state 不前進"; else bad "超上限 state 誤前進"; fi

# baseline：record base=HEAD（非 empty-tree）、C1 range=empty-tree..HEAD
git clone -q "$TMP/ra-origin.git" "$TMP/ra-base"
"$RA_SCRIPT" record --repo "$TMP/ra-base" --mode baseline >/dev/null
ra_bh="$(git -C "$TMP/ra-base" rev-parse HEAD)"
if grep -qxF "base=$ra_bh" "$(git -C "$TMP/ra-base" rev-parse --absolute-git-dir)/deep-review/anchor"; then ok "baseline record base=HEAD（非 empty-tree）"; else bad "baseline base 錯誤"; fi
out="$("$RA_SCRIPT" codex-next --repo "$TMP/ra-base")"
if grep -qxF "codex-range: 4b825dc642cb6eb9a060e54bf8d69288fbee4904..$ra_bh" <<< "$out"; then ok "baseline C1 range = empty-tree..HEAD"; else bad "baseline C1 range 錯誤"; fi

# clear：刪檔 + 幂等
"$RA_SCRIPT" clear --repo "$TMP/ra-work" >/dev/null
assert_rc "clear → exit 0" 0 $?
if [ -f "$ra_anchor" ]; then bad "clear 未刪檔"; else ok "clear 刪除 anchor 檔"; fi
"$RA_SCRIPT" clear --repo "$TMP/ra-work" >/dev/null
assert_rc "clear 幂等（檔不存在仍 0）" 0 $?

# --- untracked 目錄須展開為個別檔案（codex C3 F1）---
# 預設 `git status --porcelain` 會把整個未追蹤目錄折疊成一行 "?? dir/"，
# 而契約模板要求 reviewer「逐檔讀取」——拿到目錄會整批漏審。
git clone -q "$TMP/ra-origin.git" "$TMP/rs-unt"
mkdir -p "$TMP/rs-unt/newdir/sub"
echo x > "$TMP/rs-unt/newdir/sub/a.txt"
echo y > "$TMP/rs-unt/newdir/b.txt"
out="$("$RS_SCRIPT" "$TMP/rs-unt")"
if grep -q "newdir/sub/a.txt" <<< "$out" && grep -q "newdir/b.txt" <<< "$out"; then ok "untracked 目錄展開為個別檔案"; else bad "untracked 目錄被折疊（reviewer 會整批漏審）"; fi
if grep -qE "^  newdir/$" <<< "$out"; then bad "仍輸出折疊的目錄行"; else ok "不輸出折疊的目錄行"; fi

# --- 續跑週期計數（cycle）：R5 終止不 squash、anchor 未 clear → 重新 record 即第 2 週期 ---
# 為何：SKILL.md 要在終止報告分流「同 reviewer 再跑一輪 vs 換視角」，需要「這是第幾個週期」
# 是事實而非 model 記憶。判準取「anchor 未經 clear 就重新 record」（base hash 比對在
# working-tree 模式失效——續跑時 HEAD 已因 fix commits 前進）。
git clone -q "$TMP/ra-origin.git" "$TMP/ra-cyc"
ra_cyc_anchor="$(git -C "$TMP/ra-cyc" rev-parse --absolute-git-dir)/deep-review/anchor"
out="$("$RA_SCRIPT" record --repo "$TMP/ra-cyc" --mode working-tree)"
if grep -qxF "cycle=1" "$ra_cyc_anchor"; then ok "首次 record → cycle=1"; else bad "首次 record cycle 未落地"; fi
if grep -q "^cycle:" <<< "$out"; then bad "cycle=1 不該印告知行"; else ok "cycle=1 不印告知行（首場 review 無雜訊）"; fi
out="$("$RA_SCRIPT" record --repo "$TMP/ra-cyc" --mode working-tree)"
if grep -qxF "cycle=2" "$ra_cyc_anchor"; then ok "未 clear 即重新 record → cycle=2"; else bad "cycle 未遞增"; fi
if grep -q "^cycle: 2 " <<< "$out"; then ok "cycle≥2 印告知行（供終止報告分流）"; else bad "cycle≥2 未印告知行"; fi
if grep -q "^cycle: 2 " <<< "$("$RA_SCRIPT" show --repo "$TMP/ra-cyc")"; then ok "show 帶出 cycle（跨 session 恢復）"; else bad "show 未帶 cycle"; fi
# codex-next 會重寫整份 anchor——不可吃掉 cycle
"$RA_SCRIPT" codex-next --repo "$TMP/ra-cyc" >/dev/null
if grep -qxF "cycle=2" "$ra_cyc_anchor"; then ok "codex-next 保留 cycle"; else bad "codex-next 覆寫掉 cycle"; fi
# clear（squash 完成）→ 下一場 review 歸 1
"$RA_SCRIPT" clear --repo "$TMP/ra-cyc" >/dev/null
"$RA_SCRIPT" record --repo "$TMP/ra-cyc" --mode working-tree >/dev/null
if grep -qxF "cycle=1" "$ra_cyc_anchor"; then ok "clear 後 record → cycle 歸 1"; else bad "clear 後 cycle 未歸零"; fi

# --- 分岔歷史不誤壓（原 codex C3 F2 的回歸位）---
# record 後切到含同一 base 的 sibling branch。原實作靠 head_at_record 算「審查前既有」，
# 分岔時 base..har + har..HEAD ≠ base..HEAD 會誤報；新算法只掃 base..HEAD 的 subject，
# 結構上不可能把範圍外的 commit 算進來——本案例改守「分岔時 squash 範圍仍精確」。
git clone -q "$TMP/ra-origin.git" "$TMP/ra-imp5"
(cd "$TMP/ra-imp5" && git switch -qc feat/a \
    && echo a1 > a.txt && "${GITC[@]}" add a.txt && "${GITC[@]}" commit -qm "feat: work A")
"$RA_SCRIPT" record --repo "$TMP/ra-imp5" --mode branch-diff --base origin/main >/dev/null
ra_imp5_mb="$(git -C "$TMP/ra-imp5" rev-parse origin/main)"
(cd "$TMP/ra-imp5" && git switch -qc feat/b origin/main \
    && echo b1 > b.txt && "${GITC[@]}" add b.txt && "${GITC[@]}" commit -qm "fix: address review findings")
out="$("$RA_SCRIPT" squash-cmd --repo "$TMP/ra-imp5")"
if grep -q "^squash-preserve:" <<< "$out"; then bad "分岔歷史誤列 preserve（範圍外 commit 被算入）"; else ok "分岔時不誤列既有 commit"; fi
if grep -qxF "squash-cmd: git -C '$TMP/ra-imp5' reset --soft $ra_imp5_mb" <<< "$out"; then ok "分岔時 squash base 仍為 anchor base（全為 review commit）"; else bad "分岔時 squash base 錯誤"; fi

# --- 照抄行一律絕對路徑（相對路徑呼叫時尤其重要：照抄處的 cwd 未必是這裡）---
# 一條 case 覆蓋三種輸出；只驗絕對性，不比對整段路徑（避免與 fixture 路徑寫死耦合）
(cd "$TMP/ra-work" && "$RA_SCRIPT" record --repo . --mode branch-diff --base origin/main >/dev/null)
out="$( (cd "$TMP/ra-work" && "$RA_SCRIPT" record --repo . --mode branch-diff --base origin/main) )"
if grep -qE "^diff-cmd: git -C '/" <<< "$out"; then ok "相對 --repo → diff-cmd 印絕對路徑"; else bad "diff-cmd 沿用了相對路徑"; fi
out="$( (cd "$TMP/ra-work" && "$RA_SCRIPT" squash-cmd --repo .) )"
if grep -qE "^squash-cmd: git -C '/" <<< "$out"; then ok "相對 --repo → squash-cmd 印絕對路徑"; else bad "squash-cmd 沿用了相對路徑"; fi
out="$( (cd "$TMP/ra-work" && "$RA_SCRIPT" codex-next --repo .) )"
if grep -qE "^codex-cmd: .* --repo '/" <<< "$out"; then ok "相對 --repo → codex-cmd 印絕對路徑（下游 codex-exec-review 會對 --repo 做 -d 檢查）"; else bad "codex-cmd 沿用了相對路徑（換 cwd 執行會 exit 5 或指到別的 repo）"; fi

# --- lib 缺席：只有需要 subject 清單的 squash-cmd 該停，其餘子指令照常 ---
mkdir -p "$TMP/ra-nolib/scripts"
cp "$RA_SCRIPT" "$TMP/ra-nolib/scripts/review-anchor.sh"   # 不複製 lib/
"$TMP/ra-nolib/scripts/review-anchor.sh" record --repo "$TMP/ra-work" --mode working-tree >/dev/null 2>&1
assert_rc "lib 缺席 → record 照常（不需要 subject 清單）" 0 $?
out="$("$TMP/ra-nolib/scripts/review-anchor.sh" squash-cmd --repo "$TMP/ra-work" 2>&1)"
rc=$?
assert_rc "lib 缺席 → squash-cmd STOP（不用空 regex 硬跑）" 1 $rc
if grep -q "verdict: STOP" <<< "$out"; then ok "lib 缺席的 squash-cmd 印 STOP verdict"; else bad "缺 STOP verdict（會被當成正常結果）"; fi

# merge-base 解析失敗 → 同樣走 UNKNOWN 出口（不靜默 return，Step 4 判定表才有得對）
git clone -q "$TMP/sb-origin.git" "$TMP/rr-nomb"
(cd "$TMP/rr-nomb" && git checkout -q --orphan orphan-line \
    && git rm -rqf . 2>/dev/null; cd "$TMP/rr-nomb" && echo o > o.txt && "${GITC[@]}" add o.txt && "${GITC[@]}" commit -qm "feat: 無共同祖先")
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rr-nomb" 2>&1)"
if grep -q "^review-residue: UNKNOWN" <<< "$out"; then ok "merge-base 失敗 → review-residue 走 UNKNOWN 出口"; else bad "merge-base 失敗時靜默漏印（Step 4 判定表無列可對）"; fi

# --- option-like ref 名：quoting 擋不住，要靠 `--` terminator ---
# `git branch -- '--all'` 前端會拒，但 `git update-ref refs/heads/--all` 建得起來且
# `check-ref-format` 判合法（實測 rc=0）；quote 完 git 仍把 `--all` 當選項（codex C3）。
git init --bare -q -b main "$TMP/opt-origin.git"
git clone -q "$TMP/opt-origin.git" "$TMP/rr-opt"
(cd "$TMP/rr-opt" && echo o > o.txt && "${GITC[@]}" add o.txt && "${GITC[@]}" commit -qm init && git push -qu origin main)
git -C "$TMP/rr-opt" update-ref 'refs/heads/--all' HEAD
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rr-opt" 2>/dev/null)"
opt_cmd="$(grep '^cleanup-cmd: ' <<< "$out" | sed 's/^cleanup-cmd: //')"
if [ -n "$opt_cmd" ]; then
    if grep -qF -- "branch -d --" <<< "$opt_cmd"; then ok "cleanup-cmd 帶 -- option terminator"; else bad "cleanup-cmd 缺 --，option-like ref 會被當選項"; fi
    ( eval "$opt_cmd" ) >/dev/null 2>&1 || true
    if git -C "$TMP/rr-opt" show-ref --verify --quiet 'refs/heads/--all'; then bad "照抄 cleanup-cmd 後 option-like branch 仍在（指令實際失敗）"; else ok "照抄 cleanup-cmd 可實際刪除 option-like branch"; fi
else
    bad "未取得 cleanup-cmd（fixture 前提失效）"
fi

# --- 照抄行的 ref 名也必須 quote：git 接受 `feat/$(id)` / `feat/a;id` 這種合法 branch 名，
# 照抄含未 quote ref 的指令等於執行任意 shell（codex C2 實證 git 三種都收）---
git clone -q "$TMP/sb-origin.git" "$TMP/rr-ref"
# shellcheck disable=SC2016  # 刻意不展開：這是 fixture 要用的字面 branch 名
sq_ref_name='feat/$(id);x'   # git 接受（ref 名不可含空白，但 $ ( ) ; 皆合法）
# 不加 commit：stale-branches 只列「已完全併入 default」者（同 sb-work fixture 的做法）
(cd "$TMP/rr-ref" && git switch -qc "$sq_ref_name" \
    && git push -qu origin "$sq_ref_name" >/dev/null 2>&1 && git switch -q main)
out="$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$TMP/rr-ref" 2>/dev/null)"
ref_cmd="$(grep '^cleanup-cmd: ' <<< "$out" | sed 's/^cleanup-cmd: //')"
if [ -n "$ref_cmd" ]; then
    if bash -n <<< "$ref_cmd" 2>/dev/null; then ok "含 shell 元字元的 branch 名 → cleanup-cmd 仍可解析"; else bad "cleanup-cmd 因 ref 名破裂"; fi
    # 真正的判準：ref 取回來要與原名相同（未 quote 的話 $(…) 會被展開成別的東西或空字串）
    # 逐一比對而非「有出現就算」：cleanup-cmd 會列多個 ref（local + remote 兩處），
    # 只要有一處漏 quote 就是漏洞——出現次數必須全等於 quoted 出現次數
    n_ref_all="$(grep -oF -- "$sq_ref_name" <<< "$ref_cmd" | wc -l | tr -d ' ')"
    n_ref_q="$(grep -oF -- "'${sq_ref_name}'" <<< "$ref_cmd" | wc -l | tr -d ' ')"
    if [ "${n_ref_all:-0}" -gt 0 ] && [ "$n_ref_all" = "$n_ref_q" ]; then ok "cleanup-cmd 內每一處 ref 名都被 quote（${n_ref_q}/${n_ref_all}）"; else bad "有 ${n_ref_all} 處 ref、僅 ${n_ref_q} 處 quoted——照抄即執行任意指令"; fi
else
    bad "未取得 cleanup-cmd（fixture 前提失效）"
fi

# --- 照抄行對特殊字元路徑必須可執行（含單引號、空白、$(...)）---
# 直接把路徑插進單引號在 `/tmp/alice's-repo` 這種合法路徑上會讓 quoting 破裂，照抄行
# 送進 bash 直接 syntax error（codex C1 實證）。三支腳本共用同形的 shq helper。
sq_dir="$TMP/we'ird \$(echo x) dir"
mkdir -p "$sq_dir"
git init -q --bare -b main "$TMP/sq-origin.git"
git clone -q "$TMP/sq-origin.git" "$sq_dir/repo" 2>/dev/null
(cd "$sq_dir/repo" && echo s > s.txt && "${GITC[@]}" add s.txt && "${GITC[@]}" commit -qm init \
    && git push -qu origin main && git switch -qc feat/sq \
    && echo s2 > s.txt && "${GITC[@]}" commit -qam "feat: 語意" \
    && echo s3 > s.txt && "${GITC[@]}" commit -qam "fix: address review findings")
"$RA_SCRIPT" record --repo "$sq_dir/repo" --mode branch-diff --base origin/main >/dev/null 2>&1
sq_bad=0
for sq_line in "$("$RA_SCRIPT" record --repo "$sq_dir/repo" --mode branch-diff --base origin/main 2>/dev/null | grep '^diff-cmd: ' | sed 's/^diff-cmd: //')" \
               "$("$RA_SCRIPT" squash-cmd --repo "$sq_dir/repo" 2>/dev/null | grep '^squash-cmd: ' | sed 's/^squash-cmd: //')" \
               "$("$RA_SCRIPT" codex-next --repo "$sq_dir/repo" 2>/dev/null | grep '^codex-cmd: ' | sed 's/^codex-cmd: //')" \
               "$(SHIP_STATE_GH="$TMP/gh-open" "$SS_SCRIPT" "$sq_dir/repo" 2>/dev/null | grep '^  squash-cmd: ' | sed 's/^  squash-cmd: //')" \
               "$("$RS_SCRIPT" "$sq_dir/repo" 2>/dev/null | grep '^branch-cmd: ' | sed 's/^branch-cmd: //')"; do
    [ -n "$sq_line" ] || continue
    bash -n <<< "$sq_line" 2>/dev/null || { sq_bad=$((sq_bad + 1)); echo "     不可解析: ${sq_line}"; }
done
if [ "$sq_bad" -eq 0 ]; then ok "特殊字元路徑下所有照抄行皆可被 shell 解析"; else bad "${sq_bad} 條照抄行 quoting 破裂"; fi
# round-trip：eval 後取回的路徑必須與原路徑相同（不是「能解析」就算數）
sq_cmd="$("$RA_SCRIPT" squash-cmd --repo "$sq_dir/repo" 2>/dev/null | grep '^squash-cmd: ' | sed 's/^squash-cmd: //')"
sq_got="$(eval "set -- ${sq_cmd#git -C }"; echo "$1")"
if [ "$sq_got" = "$(cd "$sq_dir/repo" && pwd -P)" ]; then ok "照抄行的路徑 round-trip 相符（非僅可解析）"; else bad "round-trip 不符：${sq_got}"; fi

# --- 本腳本自身的防護：mktemp 失敗不得讓 TMP 退化成 cwd ---
# 為何測這個：`cd ""` 回傳 0 且不改目錄，pwd -P 會交出 cwd（本腳本第 35 行已切到 repo 根），
# 而 EXIT trap 是 `rm -rf "$TMP"`——空值 fallback 直接通向「刪掉整個 repo」。
# 用 stub 逼 mktemp 失敗——macOS 的 mktemp 會忽略無效 TMPDIR 改用預設值，設環境變數擋不住
mkdir -p "$TMP/mt-bin"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP/mt-bin/mktemp"
chmod +x "$TMP/mt-bin/mktemp"
out="$(PATH="$TMP/mt-bin:$PATH" bash -c '
    cd /tmp || exit 9
    TMP="$(mktemp -d)" || { echo GUARDED; exit 1; }
    [ -n "$TMP" ] && [ -d "$TMP" ] || { echo GUARDED; exit 1; }
    TMP="$(cd "$TMP" && pwd -P)"
    echo "UNGUARDED:$TMP"' 2>/dev/null)"
if grep -q "^GUARDED$" <<< "$out"; then ok "mktemp 失敗 → 當場中止（不讓 TMP 退化成 cwd）"; else bad "mktemp 失敗未被擋下（${out}）——EXIT trap 會 rm -rf 該目錄"; fi

# --- review-state.sh 的 lib 缺席降級（三個消費者的最後一個守門）---
mkdir -p "$TMP/rs-nolib"
cp "$RS_SCRIPT" "$TMP/rs-nolib/review-state.sh"   # 不複製 lib/
out="$("$TMP/rs-nolib/review-state.sh" "$TMP/ra-work" 2>&1)"
assert_rc "lib 缺席 → review-state 照常完成（round 以外的偵測不該被拖垮）" 0 $?
if grep -q "^round: 1（review-subjects.sh 不可用" <<< "$out"; then ok "lib 缺席 → round 降級並說明原因"; else bad "缺 round 降級（會在 set -u 下中途 unbound variable）"; fi
if grep -q "^branch-first:" <<< "$out"; then ok "lib 缺席不影響其餘偵測輸出"; else bad "lib 缺席拖垮了其他輸出"; fi

# --- terminal state：R5 終止後不得靜默重開新 cycle ---
# RED 來源（2026-08-06 實地）：第一場 R5 終止 → 人工修一條 → 又開一場（R1–R4 + C1–C3），
# 外層 orchestration 重置了輪次上限。cycle 計數判別不了成因（終止/中途停止/crash/刻意續跑），
# 故改為顯式狀態。terminate 與 resume 語意不重疊：resume 保留 base，record 是無條件覆寫。
git clone -q "$TMP/ra-origin.git" "$TMP/ra-term"
(cd "$TMP/ra-term" && git switch -qc feat/t \
    && echo t1 > t.txt && "${GITC[@]}" add t.txt && "${GITC[@]}" commit -qm "feat: 語意")
ra_term_anchor="$(git -C "$TMP/ra-term" rev-parse --absolute-git-dir)/deep-review/anchor"
"$RA_SCRIPT" record --repo "$TMP/ra-term" --mode branch-diff --base origin/main --tests-baseline pass >/dev/null
ra_term_before="$(cat "$ra_term_anchor")"

# terminate：新增三個 key，既有欄位逐一不變
"$RA_SCRIPT" terminate --repo "$TMP/ra-term" --reason r5-blocking >/dev/null
assert_rc "terminate → exit 0" 0 $?
if grep -qxF "terminal_reason=r5-blocking" "$ra_term_anchor" && grep -q "^terminal_head=" "$ra_term_anchor" && grep -q "^terminal_at=" "$ra_term_anchor"; then
    ok "terminate 寫入 terminal_reason/head/at"
else bad "terminate 未寫入三個 key"; fi
ra_term_kept=1
while IFS= read -r kv; do grep -qxF "$kv" "$ra_term_anchor" || { ra_term_kept=0; echo "     遺失: $kv"; }; done <<< "$ra_term_before"
if [ "$ra_term_kept" -eq 1 ]; then ok "terminate 逐一保留既有欄位（不覆寫 base/mode/range）"; else bad "terminate 動到既有欄位"; fi

# terminate 冪等 / 換 reason 拒絕 / 無 anchor 拒絕
"$RA_SCRIPT" terminate --repo "$TMP/ra-term" --reason r5-blocking >/dev/null 2>&1
assert_rc "terminate 同 reason 重複 → 冪等成功" 0 $?
# 本批只有一個合法 reason，故「換 reason」只可能是傳非法值 → 用法錯誤(2)，不是 STOP(1)。
# 引數合法性先於狀態檢查，是標準順序；等未來真支援多個 reason，才會有「同 anchor 換 reason」的 STOP。
"$RA_SCRIPT" terminate --repo "$TMP/ra-term" --reason codex-c3 >/dev/null 2>&1
assert_rc "terminate 非法 reason → 用法錯誤（codex-c3 無 RED，本批不支援）" 2 $?
if grep -qxF "terminal_reason=r5-blocking" "$ra_term_anchor"; then ok "非法 reason 未污染既有 terminal 狀態"; else bad "既有 terminal 被覆蓋"; fi
git clone -q "$TMP/ra-origin.git" "$TMP/ra-noanchor"
"$RA_SCRIPT" terminate --repo "$TMP/ra-noanchor" --reason r5-blocking >/dev/null 2>&1
assert_rc "terminate 無 anchor → STOP" 1 $?

# record 撞上 terminal：STOP 且**不得覆寫** anchor（寫檔前先檢查）
out="$("$RA_SCRIPT" record --repo "$TMP/ra-term" --mode working-tree 2>&1)"
rc=$?
assert_rc "terminal 狀態下 record → STOP" 1 $rc
if grep -q "verdict: STOP" <<< "$out"; then ok "record 撞 terminal 印 STOP verdict"; else bad "缺 STOP verdict"; fi
if grep -qxF "mode=branch-diff" "$ra_term_anchor"; then ok "record 撞 terminal 未覆寫 anchor（mode 仍為原值）"; else bad "record 先重算再覆蓋了 anchor"; fi

# resume-after-terminal：清 terminal、cycle +1、其餘欄位全留
ra_term_cycle_before="$(sed -n 's/^cycle=//p' "$ra_term_anchor")"
"$RA_SCRIPT" resume-after-terminal --repo "$TMP/ra-term" >/dev/null
assert_rc "resume-after-terminal → exit 0" 0 $?
if grep -q "^terminal_" "$ra_term_anchor"; then bad "resume 未清 terminal_*"; else ok "resume 清掉 terminal_*"; fi
if [ "$(sed -n 's/^cycle=//p' "$ra_term_anchor")" = "$((ra_term_cycle_before + 1))" ]; then ok "resume 使 cycle +1"; else bad "resume 未遞增 cycle"; fi
if grep -qxF "base=$(git -C "$TMP/ra-term" merge-base origin/main HEAD)" "$ra_term_anchor" && grep -qxF "tests_baseline=pass" "$ra_term_anchor"; then
    ok "resume 保留 base 與其餘欄位（與 record 的無條件覆寫語意不同）"
else bad "resume 動到 base 或其他欄位"; fi
"$RA_SCRIPT" resume-after-terminal --repo "$TMP/ra-term" >/dev/null 2>&1
assert_rc "resume 重複呼叫（已無 terminal）→ STOP" 1 $?

# 回歸鎖：非 terminal 狀態下 record 行為不變
"$RA_SCRIPT" record --repo "$TMP/ra-term" --mode working-tree >/dev/null 2>&1
assert_rc "非 terminal 狀態 → record 照常覆寫（行為不變）" 0 $?

# 用法錯誤 / 非 git repo
"$RA_SCRIPT" bogus --repo "$TMP/ra-work" >/dev/null 2>&1
assert_rc "未知子指令 → exit 2" 2 $?
"$RA_SCRIPT" record --repo "$TMP/ra-work" >/dev/null 2>&1
assert_rc "record 缺 --mode → exit 2" 2 $?
"$RA_SCRIPT" record --repo "$TMP/ra-work" --mode branch-diff >/dev/null 2>&1
assert_rc "branch-diff 缺 --base → exit 2" 2 $?
"$RA_SCRIPT" record --repo "$TMP/not-a-repo" --mode working-tree >/dev/null 2>&1
assert_rc "非 git repo → exit 1" 1 $?

# --- clean-room 回流改進：tests-baseline / diff-cmd / squash 既有-commit 警告 ---

# fixture：feature branch = 1 顆審查前既有 commit（feat: w feature）+ 1 顆 review fix commit
git clone -q "$TMP/ra-origin.git" "$TMP/ra-imp"
(cd "$TMP/ra-imp" \
    && git switch -qc feat/w \
    && echo w1 > w.txt && "${GITC[@]}" add w.txt && "${GITC[@]}" commit -qm "feat: w feature" \
    && echo w2 > w.txt && "${GITC[@]}" commit -qam "fix: R1 review fixes")
ra_imp_anchor="$(git -C "$TMP/ra-imp" rev-parse --absolute-git-dir)/deep-review/anchor"
ra_imp_mb="$(git -C "$TMP/ra-imp" merge-base origin/main HEAD)"

# record --tests-baseline fail → 寫入 anchor + show 顯示
"$RA_SCRIPT" record --repo "$TMP/ra-imp" --mode branch-diff --base origin/main --tests-baseline fail >/dev/null
assert_rc "record --tests-baseline → exit 0" 0 $?
if grep -qxF "tests_baseline=fail" "$ra_imp_anchor" 2>/dev/null; then ok "tests_baseline 寫入 anchor"; else bad "tests_baseline 未寫入 anchor"; fi
out="$("$RA_SCRIPT" show --repo "$TMP/ra-imp" 2>/dev/null)"
if grep -q "tests-baseline: fail" <<< "$out"; then ok "show 顯示 tests-baseline"; else bad "show 未顯示 tests-baseline"; fi

# codex-next 改寫 anchor 時保留 tests_baseline（否則 autocodex 階段丟失 baseline 資訊）
"$RA_SCRIPT" codex-next --repo "$TMP/ra-imp" >/dev/null 2>&1
if grep -qxF "tests_baseline=fail" "$ra_imp_anchor" 2>/dev/null; then ok "codex-next 保留 tests_baseline"; else bad "codex-next 丟失 tests_baseline"; fi

# record（branch-diff）輸出 diff-cmd 整行（固定 hash，照抄慣例）
out="$("$RA_SCRIPT" record --repo "$TMP/ra-imp" --mode branch-diff --base origin/main --tests-baseline pass 2>/dev/null)"
if grep -qxF "diff-cmd: git -C '$TMP/ra-imp' diff $ra_imp_mb...HEAD" <<< "$out"; then ok "record 印 diff-cmd（固定 hash）"; else bad "diff-cmd 缺失或錯誤"; fi

# range 模式不印 diff-cmd（審查指令 = range 引數本身，...HEAD 會審錯範圍）
out="$("$RA_SCRIPT" record --repo "$TMP/ra-imp" --mode range --range "$ra_imp_mb..HEAD" 2>/dev/null)"
if grep -q "^diff-cmd:" <<< "$out"; then bad "range 模式誤印 diff-cmd"; else ok "range 模式不印 diff-cmd"; fi

# tests-baseline 值域驗證
"$RA_SCRIPT" record --repo "$TMP/ra-imp" --mode working-tree --tests-baseline bogus >/dev/null 2>&1
assert_rc "tests-baseline 非法值 → exit 2" 2 $?

# 無 flag 覆蓋 → tests_baseline 不殘留（record 無條件覆蓋語意）
"$RA_SCRIPT" record --repo "$TMP/ra-imp" --mode branch-diff --base origin/main >/dev/null
if grep -q "^tests_baseline=" "$ra_imp_anchor"; then bad "無 flag 時 tests_baseline 殘留"; else ok "無 flag 覆蓋 → tests_baseline 不殘留"; fi

# squash base 避開既有語意 commit：branch 上的 feat 保留，只壓其上的 review fix
ra_imp_feat="$(git -C "$TMP/ra-imp" rev-parse HEAD~1)"
out="$("$RA_SCRIPT" squash-cmd --repo "$TMP/ra-imp")"
if grep -qxF "squash-cmd: git -C '$TMP/ra-imp' reset --soft $ra_imp_feat" <<< "$out"; then ok "squash base = 既有 feat commit（只壓其上的 review fix）"; else bad "squash base 未停在既有語意 commit"; fi
if grep -q "^squash-preserve: 1 顆" <<< "$out" && grep -q "feat: w feature" <<< "$out"; then ok "squash-preserve 列出被保留的 feat"; else bad "squash-preserve 缺失"; fi

# 撞名取捨（原 codex C2 F3 的位置）：使用者手寫的 commit 若 subject 恰為 review 固定樣式，
# 會被當成 review 產生而壓掉。四個樣式都是機械字串、人工撞名機率極低，且後果等同舊行為
# （舊實作同樣全壓、只多印一行 warning），故接受此代價、不加 head_at_record 之類的補償機制。
git clone -q "$TMP/ra-origin.git" "$TMP/ra-imp4"
(cd "$TMP/ra-imp4" && git switch -qc feat/collide \
    && echo p1 > p.txt && "${GITC[@]}" add p.txt && "${GITC[@]}" commit -qm "fix: address review findings")
"$RA_SCRIPT" record --repo "$TMP/ra-imp4" --mode branch-diff --base origin/main >/dev/null
ra_imp4_mb="$(git -C "$TMP/ra-imp4" rev-parse origin/main)"
(cd "$TMP/ra-imp4" && echo p2 > p.txt && "${GITC[@]}" commit -qam "fix: address review findings")
out="$("$RA_SCRIPT" squash-cmd --repo "$TMP/ra-imp4")"
if grep -qxF "squash-cmd: git -C '$TMP/ra-imp4' reset --soft $ra_imp4_mb" <<< "$out"; then ok "全為 review 樣式 → squash base 退回 anchor base（下界保護）"; else bad "全樣式時 squash base 錯誤"; fi
if grep -q "^squash-preserve:" <<< "$out"; then bad "全為 review 樣式卻列 preserve"; else ok "全為 review 樣式 → 不列 preserve"; fi

# review commit 被非 review commit 隔開（HEAD 本身即非 review）→ 保守不跨越，
# 範圍歸零，且下方未納入的 review 樣式 commit 須以 squash-note 攤開讓使用者看見。
(cd "$TMP/ra-imp4" && echo p3 > p.txt && "${GITC[@]}" commit -qam "feat: unrelated work")
out="$("$RA_SCRIPT" squash-cmd --repo "$TMP/ra-imp4")"
if grep -q "^squash-note: 保留範圍內仍有 2 顆 review 樣式 commit" <<< "$out"; then ok "被隔開的 review commit 以 squash-note 告知"; else bad "squash-note 缺失或顆數錯誤"; fi
if grep -q "WARNING" <<< "$out"; then ok "HEAD 即非 review commit → 無 commit 可 squash"; else bad "應報無 commit 可 squash"; fi

# 三段交錯：squash 範圍非空 **且** 同時有 squash-note（squash_base 嚴格落在 base 與 HEAD 之間）
git clone -q "$TMP/ra-origin.git" "$TMP/ra-mix"
(cd "$TMP/ra-mix" && git switch -qc feat/mix \
    && echo m1 > m.txt && "${GITC[@]}" add m.txt && "${GITC[@]}" commit -qm "fix: address review findings" \
    && echo m2 > m.txt && "${GITC[@]}" commit -qam "feat: 中間插入的語意 commit")
ra_mix_feat="$(git -C "$TMP/ra-mix" rev-parse HEAD)"
(cd "$TMP/ra-mix" && echo m3 > m.txt && "${GITC[@]}" commit -qam "fix: address review findings")
"$RA_SCRIPT" record --repo "$TMP/ra-mix" --mode branch-diff --base origin/main >/dev/null
out="$("$RA_SCRIPT" squash-cmd --repo "$TMP/ra-mix")"
if grep -qxF "squash-cmd: git -C '$TMP/ra-mix' reset --soft $ra_mix_feat" <<< "$out"; then ok "交錯：squash base 停在中間的語意 commit"; else bad "交錯情境 squash base 錯誤"; fi
if grep -q "^squash-range: .*（1 commit）" <<< "$out"; then ok "交錯：squash 範圍非空（1 顆）"; else bad "交錯情境範圍錯誤"; fi
if grep -q "^squash-note: 保留範圍內仍有 1 顆 review 樣式 commit" <<< "$out"; then ok "交錯：範圍非空時仍印 squash-note"; else bad "範圍非空時漏印 squash-note"; fi

# 全為 review 產生的 commits（wip snapshot + fix）→ base 不動、無 preserve
git clone -q "$TMP/ra-origin.git" "$TMP/ra-imp2"
"$RA_SCRIPT" record --repo "$TMP/ra-imp2" --mode working-tree >/dev/null
ra_imp2_base="$(git -C "$TMP/ra-imp2" rev-parse HEAD)"
(cd "$TMP/ra-imp2" && git switch -qc feat/v \
    && echo v1 > v.txt && "${GITC[@]}" add v.txt && "${GITC[@]}" commit -qm "wip: pre-review snapshot" \
    && echo v2 > v.txt && "${GITC[@]}" commit -qam "fix: R1 review fixes")
out="$("$RA_SCRIPT" squash-cmd --repo "$TMP/ra-imp2")"
if grep -q "^squash-preserve:" <<< "$out"; then bad "純 review commits 誤列 preserve"; else ok "純 review commits 無 preserve"; fi
if grep -qxF "squash-cmd: git -C '$TMP/ra-imp2' reset --soft $ra_imp2_base" <<< "$out"; then ok "working-tree 模式行為不變（base = anchor base）"; else bad "working-tree 模式 squash base 漂移"; fi

# 中性化 commit message（不編輪號，避免 reviewer 跑 git log 反推進度）：
# 新格式須被認得，且舊格式仍認（歷史 branch 上還有舊 commit，誤判會噴假 warning）
git clone -q "$TMP/ra-origin.git" "$TMP/ra-imp3"
"$RA_SCRIPT" record --repo "$TMP/ra-imp3" --mode working-tree >/dev/null
ra_imp3_base="$(git -C "$TMP/ra-imp3" rev-parse HEAD)"
(cd "$TMP/ra-imp3" && git switch -qc feat/n \
    && echo n1 > n.txt && "${GITC[@]}" add n.txt && "${GITC[@]}" commit -qm "wip: pre-review snapshot" \
    && echo n2 > n.txt && "${GITC[@]}" commit -qam "fix: address review findings" \
    && echo n3 > n.txt && "${GITC[@]}" commit -qam "fix: address review findings" \
    && echo n4 > n.txt && "${GITC[@]}" commit -qam "fix: address external review findings" \
    && echo n5 > n.txt && "${GITC[@]}" commit -qam "fix: R1 review fixes" \
    && echo n6 > n.txt && "${GITC[@]}" commit -qam "fix: codex C1 fixes" \
    && echo n7 > n.txt && "${GITC[@]}" commit -qam "fix: codex R1 fixes")
out="$("$RA_SCRIPT" squash-cmd --repo "$TMP/ra-imp3")"
if grep -qxF "squash-cmd: git -C '$TMP/ra-imp3' reset --soft $ra_imp3_base" <<< "$out"; then ok "中性/舊格式 commit message 皆認得（新舊並存、全數納入 squash）"; else bad "中性化或舊格式 message 未被認出（squash base 提前停下）"; fi
if grep -q "^squash-preserve:" <<< "$out"; then bad "全為 review 樣式卻列 preserve"; else ok "六種樣式全認得 → 無 preserve"; fi
# 反向：真的語意 commit 仍要擋住掃描（不因放寬 pattern 而越界壓掉）
(cd "$TMP/ra-imp3" && echo n8 > n.txt && "${GITC[@]}" commit -qam "feat: unrelated work")
ra_imp3_feat="$(git -C "$TMP/ra-imp3" rev-parse HEAD)"
out="$("$RA_SCRIPT" squash-cmd --repo "$TMP/ra-imp3")"
if grep -qxF "squash-cmd: git -C '$TMP/ra-imp3' reset --soft $ra_imp3_feat" <<< "$out"; then ok "放寬 pattern 後語意 commit 仍擋得住掃描"; else bad "語意 commit 被越過（會被誤壓）"; fi
if grep -q "^squash-note: 保留範圍內仍有 7 顆 review 樣式 commit" <<< "$out"; then ok "被隔開的 7 顆 review commit 以 squash-note 攤開"; else bad "squash-note 顆數錯誤或缺失"; fi

# --- 續跑（cycle≥2）：兩場 review 的 fix commit 一併壓，base 不停在上一場的 fix ---
# 為何：續跑時 record 重跑、head_at_record 前移，若拿它當下界，上一場的 fix commit 會殘留
# 在 branch 上（無語意、無參照價值）。純 subject 掃描天然不受 record 次數影響。
git clone -q "$TMP/ra-origin.git" "$TMP/ra-cyc2"
(cd "$TMP/ra-cyc2" && git switch -qc feat/cyc \
    && echo c1 > c.txt && "${GITC[@]}" add c.txt && "${GITC[@]}" commit -qm "feat: base work")
ra_cyc2_feat="$(git -C "$TMP/ra-cyc2" rev-parse HEAD)"
"$RA_SCRIPT" record --repo "$TMP/ra-cyc2" --mode branch-diff --base origin/main >/dev/null
(cd "$TMP/ra-cyc2" && echo c2 > c.txt && "${GITC[@]}" commit -qam "fix: address review findings")
"$RA_SCRIPT" record --repo "$TMP/ra-cyc2" --mode branch-diff --base origin/main >/dev/null
(cd "$TMP/ra-cyc2" && echo c3 > c.txt && "${GITC[@]}" commit -qam "fix: address review findings")
out="$("$RA_SCRIPT" squash-cmd --repo "$TMP/ra-cyc2")"
if grep -qxF "squash-cmd: git -C '$TMP/ra-cyc2' reset --soft $ra_cyc2_feat" <<< "$out"; then ok "續跑：兩場的 fix commit 一併壓、停在 feat"; else bad "續跑時 squash base 錯誤（上一場 fix 殘留）"; fi
if grep -q "^squash-preserve: 1 顆" <<< "$out"; then ok "續跑：既有 feat 仍保留"; else bad "續跑 preserve 錯誤"; fi

echo "▶ 20. verify-tests.sh（deep-review skill script）框架偵測與 exit 契約（uv/bun stub）"
VT_SCRIPT="$ROOT/claude/skills/deep-review/scripts/verify-tests.sh"

# stub：PATH 前置注入假 uv/bun；argv 落檔供斷言（打真實 argv，不打重建字串）
mkdir -p "$TMP/vt-bin"
cat > "$TMP/vt-bin/uv" <<'STUB'
#!/usr/bin/env bash
[ -n "${VT_UV_ARGV:-}" ] && printf '%s\n' "$@" > "$VT_UV_ARGV"
exit "${VT_UV_RC:-0}"
STUB
cat > "$TMP/vt-bin/bun" <<'STUB'
#!/usr/bin/env bash
[ -n "${VT_BUN_ARGV:-}" ] && printf '%s\n' "$@" > "$VT_BUN_ARGV"
if [ "${VT_BUN_MODE:-ok}" = "notests" ]; then
    echo 'error: 0 test files matching **{.test,.spec,_test_,_spec_}.{js,ts,jsx,tsx} in --cwd=/x' >&2
    exit 1
fi
exit "${VT_BUN_RC:-0}"
STUB
chmod +x "$TMP/vt-bin/uv" "$TMP/vt-bin/bun"
vt_run() { PATH="$TMP/vt-bin:$PATH" "$VT_SCRIPT" "$@"; }

# pytest：rc 0/1/5 → exit 0/1/3
mkdir -p "$TMP/vt-py" && touch "$TMP/vt-py/pyproject.toml"
VT_UV_ARGV="$TMP/vt-uv-argv" vt_run "$TMP/vt-py" >/dev/null
assert_rc "pytest 全綠 → exit 0（PASS）" 0 $?
assert_eq "stub 收到真實 argv：uv run pytest" "run
pytest" "$(cat "$TMP/vt-uv-argv")"
out="$(VT_UV_RC=1 vt_run "$TMP/vt-py")"
assert_rc "pytest 紅 → exit 1（FAIL）" 1 $?
if grep -q "verdict: FAIL" <<< "$out"; then ok "FAIL 印 verdict 行"; else bad "FAIL verdict 缺失"; fi
VT_UV_RC=5 vt_run "$TMP/vt-py" >/dev/null
assert_rc "pytest rc=5（no tests collected）→ exit 3（SKIP）" 3 $?

# bun：test script 存在 → 執行；紅 / 無測試檔 / placeholder → 1 / 3 / 3
mkdir -p "$TMP/vt-js"
echo '{"scripts":{"test":"bun test"}}' > "$TMP/vt-js/package.json"
VT_BUN_ARGV="$TMP/vt-bun-argv" vt_run "$TMP/vt-js" >/dev/null
assert_rc "bun test 全綠 → exit 0" 0 $?
assert_eq "stub 收到真實 argv：bun test" "test" "$(cat "$TMP/vt-bun-argv")"
VT_BUN_RC=1 vt_run "$TMP/vt-js" >/dev/null
assert_rc "bun test 紅 → exit 1" 1 $?
VT_BUN_MODE=notests vt_run "$TMP/vt-js" >/dev/null
assert_rc "bun 無測試檔（0 test files matching）→ exit 3" 3 $?
mkdir -p "$TMP/vt-js-ph"
printf '{"scripts":{"test":"echo \\"Error: no test specified\\" && exit 1"}}\n' > "$TMP/vt-js-ph/package.json"
VT_BUN_ARGV="$TMP/vt-bun-ph-argv" vt_run "$TMP/vt-js-ph" >/dev/null
assert_rc "npm placeholder test script → exit 3" 3 $?
if [ -f "$TMP/vt-bun-ph-argv" ]; then bad "placeholder 不應執行 bun"; else ok "placeholder 未執行 bun（無 argv 落檔）"; fi

# 並存（monorepo）：都跑；任一紅即 FAIL
mkdir -p "$TMP/vt-both" && touch "$TMP/vt-both/pyproject.toml"
echo '{"scripts":{"test":"bun test"}}' > "$TMP/vt-both/package.json"
VT_UV_ARGV="$TMP/vt-both-uv" VT_BUN_ARGV="$TMP/vt-both-bun" vt_run "$TMP/vt-both" >/dev/null
assert_rc "並存皆綠 → exit 0" 0 $?
if [ -f "$TMP/vt-both-uv" ] && [ -f "$TMP/vt-both-bun" ]; then ok "並存 → 兩個框架都被執行"; else bad "並存未都執行"; fi
VT_BUN_RC=1 vt_run "$TMP/vt-both" >/dev/null
assert_rc "並存任一紅 → exit 1" 1 $?

# 無框架 / 用法錯誤
mkdir -p "$TMP/vt-none"
out="$(vt_run "$TMP/vt-none")"
assert_rc "無框架 → exit 3（SKIP）" 3 $?
if grep -q "verdict: SKIP" <<< "$out"; then ok "SKIP 印 verdict 行"; else bad "SKIP verdict 缺失"; fi
vt_run >/dev/null 2>&1
assert_rc "缺引數 → exit 2" 2 $?
vt_run "$TMP/vt-nope" >/dev/null 2>&1
assert_rc "路徑不存在 → exit 2" 2 $?
