#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 18. ensure-codex-skills.sh 幂等連結 Codex skill"
ECS="$ROOT/scripts/ensure-codex-skills.sh"
ecs="$TMP/ecs"
mkdir -p "$ecs/src/repo-review" "$ecs/src/physical-skill" "$ecs/src/third-party" "$ecs/src/broken" \
    "$ecs/src/not-a-skill" "$ecs/dst/.system" "$ecs/legacy/.system" "$ecs/external/third-party"
echo "# skill" > "$ecs/src/repo-review/SKILL.md"
echo "# physical" > "$ecs/src/physical-skill/SKILL.md"
echo "# third-party" > "$ecs/src/third-party/SKILL.md"
echo "# broken" > "$ecs/src/broken/SKILL.md"
echo "noise"   > "$ecs/src/not-a-skill/README.md"
ln -s "$ecs/src/repo-review" "$ecs/legacy/repo-review"
mkdir -p "$ecs/legacy/physical-skill"
ln -s "$ecs/external/third-party" "$ecs/legacy/third-party"
ln -s "$ecs/missing" "$ecs/legacy/broken"

# 目的地是舊的實體目錄 → 換成 symlink（這正是 7/20 實證的 stale 情境）
mkdir -p "$ecs/dst/repo-review" && echo "# 舊版" > "$ecs/dst/repo-review/SKILL.md"
SRC_ROOT="$ecs/src" DST_ROOT="$ecs/dst" LEGACY_ROOT="$ecs/legacy" bash "$ECS"
assert_rc "實體舊目錄 → exit 0" 0 $?
if [ -L "$ecs/dst/repo-review" ]; then ok "舊實體目錄已換成 symlink"; else bad "仍是實體目錄"; fi
assert_eq "symlink 指向 dotfiles 來源" "$ecs/src/repo-review" "$(readlink "$ecs/dst/repo-review")"
assert_eq "透過 symlink 讀到新版內容" "# skill" "$(cat "$ecs/dst/repo-review/SKILL.md")"

# 無 SKILL.md 的目錄不接管；discovery root 下的其他項目（.system）不動
if [ ! -e "$ecs/dst/not-a-skill" ]; then ok "無 SKILL.md 的目錄不建連結"; else bad "誤建了非 skill 連結"; fi
if [ -d "$ecs/dst/.system" ] && [ ! -L "$ecs/dst/.system" ]; then ok ".system 未被動到"; else bad ".system 被誤動"; fi
if [ ! -e "$ecs/legacy/repo-review" ]; then
    ok "新 link 驗證後移除 repo-managed legacy symlink"
else bad "repo-managed legacy symlink 未清理"; fi
if [ -d "$ecs/legacy/physical-skill" ] && [ ! -L "$ecs/legacy/physical-skill" ]; then
    ok "legacy 實體目錄不動"
else bad "legacy 實體目錄被誤接管"; fi
if [ -L "$ecs/legacy/third-party" ] && [ "$ecs/legacy/third-party" -ef "$ecs/external/third-party" ]; then
    ok "legacy 第三方 symlink 不動"
else bad "legacy 第三方 symlink 被誤刪"; fi
if [ -L "$ecs/legacy/broken" ]; then ok "legacy 斷鏈不猜測所有權"; else bad "legacy 斷鏈被誤刪"; fi
if [ -d "$ecs/legacy/.system" ] && [ ! -L "$ecs/legacy/.system" ]; then ok "legacy .system 不動"; else bad "legacy .system 被誤動"; fi

# 接管實體目錄須「備份而非刪除」：此腳本每台每次 dotsync 都跑，直接 rm -rf 等於把
# 手工修改的內容不可逆地消滅。備份區必須在 DST_ROOT 之外——codex 會把 skills/ 下每個
# 目錄當 skill 載入，備份留在裡面會變成另一個過期 skill。
if find "$ecs/dst-backup" -name SKILL.md 2>/dev/null | grep -q .; then
    ok "原實體目錄已備份（非直接刪除）"
else bad "原實體目錄被直接刪除，內容不可回收"; fi
if grep -rq '舊版' "$ecs/dst-backup" 2>/dev/null; then
    ok "備份保留了接管前的內容"
else bad "備份內容不正確"; fi
if [ -z "$(find "$ecs/dst" -maxdepth 1 -name 'repo-review-*' 2>/dev/null)" ]; then
    ok "備份未留在 skills/ 內（不會被當成另一個 skill）"
else bad "備份留在 skills/ 內，會被 codex 當成另一個過期 skill"; fi

# ln 失敗須回報而非靜默成功（rm/mv 已把原目錄移走，此時失敗＝skill 消失）。
# 用 ln stub 而非 chmod 500：root（容器／CI）可繞過 mode bits 讓 ln 意外成功 → 測試不可攜。
ecs_ro="$TMP/ecs-ro"
mkdir -p "$ecs_ro/src/s1" "$ecs_ro/dst" "$ecs_ro/bin"
echo "# s" > "$ecs_ro/src/s1/SKILL.md"
mkdir -p "$ecs_ro/legacy"
ln -s "$ecs_ro/src/s1" "$ecs_ro/legacy/s1"
printf '#!/usr/bin/env bash\nexit 1\n' > "$ecs_ro/bin/ln"
chmod +x "$ecs_ro/bin/ln"
ecs_out="$(PATH="$ecs_ro/bin:$PATH" SRC_ROOT="$ecs_ro/src" DST_ROOT="$ecs_ro/dst" \
    LEGACY_ROOT="$ecs_ro/legacy" BACKUP_ROOT="$ecs_ro/bak" bash "$ECS" 2>&1)"
ecs_rc=$?
assert_rc "ln 失敗 → exit 非 0（不報成功）" 1 "$ecs_rc"
if grep -q '⚠️' <<< "$ecs_out"; then ok "ln 失敗印出警告（stdout，不被 2>/dev/null 吞）"; else bad "ln 失敗無警告"; fi
if [ -L "$ecs_ro/legacy/s1" ]; then ok "新 links 未全綠時不清 legacy"; else bad "新 link 失敗卻刪了 legacy fallback"; fi

# 重跑幂等：已是正確 symlink → 不動檔（比對 inode 確認沒有 rm+重建）
# stat -c 先試（GNU 成功、BSD 失敗）再退 -f；順序不可顛倒——GNU 的 -f 是「檔案系統」會假成功
ecs_inode() { stat -c %i "$1" 2>/dev/null || stat -f %i "$1" 2>/dev/null; }
ecs_before="$(ecs_inode "$ecs/dst/repo-review")"
SRC_ROOT="$ecs/src" DST_ROOT="$ecs/dst" LEGACY_ROOT="$ecs/legacy" bash "$ECS"
ecs_after="$(ecs_inode "$ecs/dst/repo-review")"
assert_eq "重跑幂等（symlink 未重建）" "$ecs_before" "$ecs_after"

# 來源不存在 → 靜默 exit 0，不建立目的地
SRC_ROOT="$ecs/nonexistent" DST_ROOT="$ecs/dst2" LEGACY_ROOT="$ecs/legacy2" bash "$ECS"
assert_rc "來源不存在 → exit 0" 0 $?
if [ ! -e "$ecs/dst2" ]; then ok "來源不存在 → 不建立目的地"; else bad "來源不存在卻建了目的地"; fi

# dotfiles-sync.sh 遠端回報段：撈 ↻ 告知的 pipeline 在 set -euo pipefail 下不可吃掉成敗回報。
# （實證：grep 無配對回 1 + pipefail + set -e → sync_remote 提早退出，所有主機的 ✅/⚠️/❌ 全消失，
#   同步失敗變靜默成功。故此處測的是「無 ↻ 時仍要印出結果」這個行為。）
# fixture 自原始碼抽出整個 sync_remote（**含 ssh 賦值行**——ssh 失敗同樣會在 set -e 下
# 吞掉整段回報，若只從 ↻ 那行往下抽會繞開這個最常見的失敗路徑，給出不存在的覆蓋保證），
# 只把 ssh 指令替換成可控的假指令。
ecs_report="$TMP/ecs-report.sh"
{
    echo 'set -euo pipefail'
    # shellcheck disable=SC2016,SC2028  # 刻意寫成字面：這些要寫進 fixture 腳本、由它自己展開
    printf '%s\n' 'fake_ssh() { printf "%s\n" "$FAKE_RESULT"; return "${FAKE_RC:-0}"; }'
    # shellcheck disable=SC2016  # 刻意字面：sed 的 pattern 要比對原始碼裡的 ${GREEN} 等字樣本身
    sed -n '/^sync_remote() {/,/^}/p' "$ROOT/scripts/dotfiles-sync.sh" \
        | sed 's/ssh -o BatchMode=yes -o ConnectTimeout=5 "\$host"/fake_ssh/; s/${GREEN}//g; s/${YELLOW}//g; s/${RED}//g; s/${NC}//g; s/echo -e/echo/g'
    # shellcheck disable=SC2016  # 同上，$1 由 fixture 自己展開
    echo 'sync_remote "$1"'
} > "$ecs_report"
# 哨兵：抽取失效時直接指出「原始碼抽取失效」，而非誤導成「回報消失」
if [ -s "$ecs_report" ] && grep -q 'esac' "$ecs_report" && grep -q 'fake_ssh' "$ecs_report"; then
    ok "fixture 自 dotfiles-sync.sh 抽取成功（含 ssh 賦值行）"
else bad "fixture 抽取失效——下列斷言不具意義，請檢查 sync_remote 的結構是否變動"; fi

ecs_out="$(FAKE_RESULT="OK" bash "$ecs_report" hostA 2>&1)"
assert_rc "無 ↻ 告知時 → 回報段仍正常結束" 0 $?
if grep -q '✅ hostA' <<< "$ecs_out"; then ok "無 ↻ 時仍印出主機結果（不被 pipefail 吃掉）"; else bad "回報被 pipeline 吃掉——同步失敗會變靜默成功"; fi
ecs_out="$(FAKE_RESULT="$(printf '↻ 接管 x\nOK\n')" bash "$ecs_report" hostB 2>&1)"
if grep -q 'hostB: ↻ 接管 x' <<< "$ecs_out"; then ok "有 ↻ 時撈出並冠上主機名"; else bad "↻ 告知未被撈出"; fi
if grep -q '✅ hostB' <<< "$ecs_out"; then ok "有 ↻ 時成敗回報不受影響"; else bad "有 ↻ 時成敗回報消失"; fi
# ssh 失敗（主機不可達）→ 必須印 ❌，不可整段靜默
ecs_out="$(FAKE_RESULT="" FAKE_RC=255 bash "$ecs_report" hostC 2>&1)"
assert_rc "ssh 失敗 → sync_remote 回非零供聚合" 1 $?
if grep -q '❌ hostC' <<< "$ecs_out"; then ok "ssh 失敗 → 印出連線失敗（不靜默）"; else bad "ssh 失敗被 set -e 吞掉——同步失敗變靜默成功"; fi
ecs_out="$(FAKE_RESULT="NO_DOTFILES" bash "$ecs_report" hostD 2>&1)"
if grep -q 'hostD' <<< "$ecs_out"; then ok "NO_DOTFILES → 印出警告"; else bad "NO_DOTFILES 回報消失"; fi
# helper 部署失敗（codex C2）：終判不得仍是 ✅——自動化只讀終判會誤認部署成功
ecs_out="$(FAKE_RESULT="$(printf '⚠️ 無法建立 symlink x\nOK_HELPER_WARN\n')" bash "$ecs_report" hostE 2>&1)"
if grep -q '✅ hostE' <<< "$ecs_out"; then
    bad "helper 失敗仍判 ✅（部署失敗被誤報成功）"
else
    ok "helper 失敗不判 ✅"
fi
if grep -q '⚠️.*hostE' <<< "$ecs_out"; then ok "helper 失敗 → 終判 ⚠️"; else bad "helper 失敗無 ⚠️ 終判"; fi
# C3（codex）：↩ 還原告知也要撈出——操作者須知道原 guidance 已恢復，避免不必要的人工復原
ecs_out="$(FAKE_RESULT="$(printf '⚠️ 無法建立 symlink x\n↩ 已還原原檔 x\nOK_HELPER_WARN\n')" bash "$ecs_report" hostF 2>&1)"
if grep -q 'hostF: ↩' <<< "$ecs_out"; then ok "↩ 還原告知冠主機名撈出"; else bad "↩ 還原告知被摘要 grep 丟棄"; fi

echo "▶ 18b. ensure-codex-guidance.sh 幂等連結全域 Codex guidance"
ECG="$ROOT/scripts/ensure-codex-guidance.sh"
ecg="$TMP/ecg"
mkdir -p "$ecg/source" "$ecg/codex"
echo "# managed guidance" > "$ecg/source/AGENTS.md"
echo "# local guidance" > "$ecg/codex/AGENTS.md"

# 既有實體檔必須備份後接管，且備份區位於 Codex home 外。
SOURCE_FILE="$ecg/source/AGENTS.md" CODEX_DIR="$ecg/codex" BACKUP_ROOT="$ecg/backup" bash "$ECG"
assert_rc "guidance 實體檔接管 → exit 0" 0 $?
if [ -L "$ecg/codex/AGENTS.md" ]; then ok "guidance 目的地已換成 symlink"; else bad "guidance 目的地不是 symlink"; fi
assert_eq "guidance symlink 指向版控來源" "$ecg/source/AGENTS.md" "$(readlink "$ecg/codex/AGENTS.md")"
if grep -rq 'local guidance' "$ecg/backup" 2>/dev/null; then ok "既有全域 guidance 已備份"; else bad "既有全域 guidance 未備份"; fi
if [ "$(dirname "$ecg/backup")" != "$ecg/codex" ]; then ok "guidance 備份區在 Codex home 外"; else bad "guidance 備份留在 Codex home"; fi

# 錯誤 symlink 可替換；正確 symlink 重跑保持 inode 不變。
mkdir -p "$ecg/other" && echo wrong > "$ecg/other/AGENTS.md"
ln -sfn "$ecg/other/AGENTS.md" "$ecg/codex/AGENTS.md"
SOURCE_FILE="$ecg/source/AGENTS.md" CODEX_DIR="$ecg/codex" BACKUP_ROOT="$ecg/backup" bash "$ECG"
assert_eq "錯誤 guidance symlink 已替換" "$ecg/source/AGENTS.md" "$(readlink "$ecg/codex/AGENTS.md")"
ecg_before="$(ecs_inode "$ecg/codex/AGENTS.md")"
SOURCE_FILE="$ecg/source/AGENTS.md" CODEX_DIR="$ecg/codex" BACKUP_ROOT="$ecg/backup" bash "$ECG"
ecg_after="$(ecs_inode "$ecg/codex/AGENTS.md")"
assert_eq "guidance helper 重跑幂等" "$ecg_before" "$ecg_after"

# CODEX_HOME override、來源缺失、ln 失敗皆有明確契約。
mkdir -p "$ecg/codex-home"
SOURCE_FILE="$ecg/source/AGENTS.md" CODEX_HOME="$ecg/codex-home" BACKUP_ROOT="$ecg/home-backup" bash "$ECG"
assert_eq "CODEX_HOME override 生效" "$ecg/source/AGENTS.md" "$(readlink "$ecg/codex-home/AGENTS.md")"
SOURCE_FILE="$ecg/missing.md" CODEX_DIR="$ecg/missing-codex" bash "$ECG"
assert_rc "guidance 來源不存在 → exit 0" 0 $?
if [ ! -e "$ecg/missing-codex" ]; then ok "來源不存在不建立 Codex home"; else bad "來源不存在卻建立 Codex home"; fi
mkdir -p "$ecg/fail-codex" "$ecg/bin"
printf '#!/usr/bin/env bash\nexit 1\n' > "$ecg/bin/ln"
chmod +x "$ecg/bin/ln"
ecg_out="$(PATH="$ecg/bin:$PATH" SOURCE_FILE="$ecg/source/AGENTS.md" CODEX_DIR="$ecg/fail-codex" BACKUP_ROOT="$ecg/fail-backup" bash "$ECG" 2>&1)"
ecg_rc=$?
assert_rc "guidance ln 失敗 → exit 非 0" 1 "$ecg_rc"
if grep -q '⚠️' <<< "$ecg_out"; then ok "guidance ln 失敗印警告"; else bad "guidance ln 失敗無警告"; fi
# ln 失敗且原檔已被搬去備份 → 必須還原，原有 guidance 不得從生效位置消失（codex C2）
mkdir -p "$ecg/restore-codex"
echo "# precious guidance" > "$ecg/restore-codex/AGENTS.md"
PATH="$ecg/bin:$PATH" SOURCE_FILE="$ecg/source/AGENTS.md" CODEX_DIR="$ecg/restore-codex" \
    BACKUP_ROOT="$ecg/restore-backup" bash "$ECG" >/dev/null 2>&1
assert_rc "既有實體檔 + ln 失敗 → exit 1" 1 $?
if [ -f "$ecg/restore-codex/AGENTS.md" ] && grep -q 'precious guidance' "$ecg/restore-codex/AGENTS.md"; then
    ok "ln 失敗後原檔已還原（guidance 不消失）"
else
    bad "ln 失敗後原檔消失（僅剩備份）"
fi

# brewup 也必須接上：allup 走的是 brewup 而非 dotsync，只掛 dotfiles-sync 等於
# 「日常全機隊更新」不重建 symlink，來源檔改名時該連結靜默失效。
for wiring_file in setup-mac-env.sh setup-linux-env.sh scripts/dotfiles-sync.sh scripts/brewup.sh; do
    if grep -q 'ensure-runtime.sh' "$ROOT/$wiring_file"; then
        ok "$wiring_file 已接上 共用 runtime entry"
    else
        bad "$wiring_file 未接上 共用 runtime entry"
    fi
done
for setup_file in setup-mac-env.sh setup-linux-env.sh; do
    # shellcheck disable=SC2016  # 刻意比對 setup 原始碼中的字面 $SCRIPT_DIR，不在測試 shell 展開
    if grep -q 'DOTFILES_DIR="$SCRIPT_DIR" bash "$SCRIPT_DIR/scripts/ensure-runtime.sh"' "$ROOT/$setup_file"; then
        ok "$setup_file 以實際 clone 路徑部署 runtime"
    else
        bad "$setup_file 未把實際 clone 路徑傳給 runtime entry"
    fi
done

echo "▶ 18c. ensure-lftprc.sh 幂等連結 ~/.lftprc（含 .lftprc.local 契約）"
ELR="$ROOT/scripts/ensure-lftprc.sh"
elr="$TMP/elr"
mkdir -p "$elr/source" "$elr/home"
echo "# managed lftprc" > "$elr/source/lftprc"
echo "# my own lftprc" > "$elr/home/.lftprc"

# 既有實體檔必須備份後接管，不得直接刪除使用者設定。
SOURCE_FILE="$elr/source/lftprc" TARGET_HOME="$elr/home" BACKUP_ROOT="$elr/backup" bash "$ELR" >/dev/null
assert_rc "lftprc 實體檔接管 → exit 0" 0 $?
if [ -L "$elr/home/.lftprc" ]; then ok "lftprc 目的地已換成 symlink"; else bad "lftprc 目的地不是 symlink"; fi
assert_eq "lftprc symlink 指向版控來源" "$elr/source/lftprc" "$(readlink "$elr/home/.lftprc")"
if grep -rq 'my own lftprc' "$elr/backup" 2>/dev/null; then ok "既有 lftprc 已備份"; else bad "既有 lftprc 未備份"; fi
# lftprc 結尾 source ~/.lftprc.local，缺檔會讓 lftp 每次啟動印錯誤
if [ -f "$elr/home/.lftprc.local" ]; then ok "已自動建立 .lftprc.local"; else bad "未建立 .lftprc.local"; fi

# .lftprc.local 是使用者的機器特定設定——重跑絕不可清空
echo "set net:timeout 99" > "$elr/home/.lftprc.local"
SOURCE_FILE="$elr/source/lftprc" TARGET_HOME="$elr/home" BACKUP_ROOT="$elr/backup" bash "$ELR" >/dev/null
if grep -q 'net:timeout 99' "$elr/home/.lftprc.local"; then ok "重跑不覆寫既有 .lftprc.local"; else bad "重跑清空了 .lftprc.local"; fi

# symlink 已正確時的早退路徑仍須補回被刪掉的 .lftprc.local（易漏）
rm -f "$elr/home/.lftprc.local"
SOURCE_FILE="$elr/source/lftprc" TARGET_HOME="$elr/home" BACKUP_ROOT="$elr/backup" bash "$ELR" >/dev/null
if [ -f "$elr/home/.lftprc.local" ]; then ok "symlink 已正確時仍補回 .lftprc.local"; else bad "早退路徑跳過 .lftprc.local"; fi

# 錯誤 symlink 可替換；正確 symlink 重跑保持 inode 不變。
mkdir -p "$elr/other" && echo wrong > "$elr/other/lftprc"
ln -sfn "$elr/other/lftprc" "$elr/home/.lftprc"
SOURCE_FILE="$elr/source/lftprc" TARGET_HOME="$elr/home" BACKUP_ROOT="$elr/backup" bash "$ELR" >/dev/null
assert_eq "錯誤 lftprc symlink 已替換" "$elr/source/lftprc" "$(readlink "$elr/home/.lftprc")"
elr_before="$(ecs_inode "$elr/home/.lftprc")"
SOURCE_FILE="$elr/source/lftprc" TARGET_HOME="$elr/home" BACKUP_ROOT="$elr/backup" bash "$ELR" >/dev/null
elr_after="$(ecs_inode "$elr/home/.lftprc")"
assert_eq "lftprc helper 重跑幂等" "$elr_before" "$elr_after"

# 來源不存在（舊 clone 尚未 pull 到 lftprc）→ 靜默 exit 0，不留半成品
mkdir -p "$elr/empty-home"
SOURCE_FILE="$elr/missing-lftprc" TARGET_HOME="$elr/empty-home" bash "$ELR" >/dev/null
assert_rc "lftprc 來源不存在 → exit 0" 0 $?
if [ ! -e "$elr/empty-home/.lftprc" ] && [ ! -e "$elr/empty-home/.lftprc.local" ]; then
    ok "來源不存在不建立任何 lftp 檔案"
else
    bad "來源不存在卻建立了 lftp 檔案"
fi

# ln 失敗 → 非 0 + 警告；原檔已搬去備份時必須還原（同 guidance 的 codex C2 契約）
mkdir -p "$elr/fail-home" "$elr/bin"
printf '#!/usr/bin/env bash\nexit 1\n' > "$elr/bin/ln"
chmod +x "$elr/bin/ln"
elr_out="$(PATH="$elr/bin:$PATH" SOURCE_FILE="$elr/source/lftprc" TARGET_HOME="$elr/fail-home" BACKUP_ROOT="$elr/fail-backup" bash "$ELR" 2>&1)"
elr_rc=$?
assert_rc "lftprc ln 失敗 → exit 非 0" 1 "$elr_rc"
if grep -q '⚠️' <<< "$elr_out"; then ok "lftprc ln 失敗印警告"; else bad "lftprc ln 失敗無警告"; fi
mkdir -p "$elr/restore-home"
echo "# precious lftprc" > "$elr/restore-home/.lftprc"
PATH="$elr/bin:$PATH" SOURCE_FILE="$elr/source/lftprc" TARGET_HOME="$elr/restore-home" \
    BACKUP_ROOT="$elr/restore-backup" bash "$ELR" >/dev/null 2>&1
assert_rc "既有實體 lftprc + ln 失敗 → exit 1" 1 $?
if [ -f "$elr/restore-home/.lftprc" ] && grep -q 'precious lftprc' "$elr/restore-home/.lftprc"; then
    ok "ln 失敗後原 lftprc 已還原（設定不消失）"
else
    bad "ln 失敗後原 lftprc 消失（僅剩備份）"
fi

for wiring_file in setup-mac-env.sh setup-linux-env.sh scripts/dotfiles-sync.sh scripts/brewup.sh; do
    if grep -q 'ensure-lftprc.sh' "$ROOT/$wiring_file"; then
        ok "$wiring_file 已接上 lftprc helper"
    else
        bad "$wiring_file 未接上 lftprc helper"
    fi
done
# dotfiles-sync 需本機段與遠端段都呼叫，否則遠端主機拿不到 config
assert_eq "dotfiles-sync 本機+遠端兩處都呼叫 lftprc helper" 2 \
    "$(grep -c 'ensure-lftprc.sh' "$ROOT/scripts/dotfiles-sync.sh")"
for setup_file in setup-mac-env.sh setup-linux-env.sh; do
    # shellcheck disable=SC2016  # 刻意比對 setup 原始碼中的字面 $SCRIPT_DIR，不在測試 shell 展開
    if grep -q 'DOTFILES_DIR="$SCRIPT_DIR" bash "$SCRIPT_DIR/scripts/ensure-lftprc.sh"' "$ROOT/$setup_file"; then
        ok "$setup_file 以實際 clone 路徑部署 lftprc"
    else
        bad "$setup_file 未把實際 clone 路徑傳給 lftprc helper"
    fi
done

echo "▶ 18d. brewup.sh helper 部署與失敗告知（全隔離）"
# brewup 除了 helper 還會跑 git / brew / claude / jq 與 cp known_hosts。fixture 必須同時
# 隔離 DOTFILES_DIR、HOME 與 PATH——否則這節測試本身會去動真的 repo、真的 Homebrew 與真的 $HOME。
BUP="$ROOT/scripts/brewup.sh"
bup="$TMP/bup"
bup_real_home="$HOME"
bup_real_kh_sum=""
[ -f "$bup_real_home/.ssh/known_hosts" ] && bup_real_kh_sum="$(cksum < "$bup_real_home/.ssh/known_hosts")"
mkdir -p "$bup/dotfiles/scripts" "$bup/dotfiles/claude" "$bup/dotfiles/ssh" "$bup/home/.ssh" "$bup/bin" "$bup/marks"

# 受控 stub：只記錄被呼叫，不做任何真事
# bun 必須在這裡就備妥——第 6 節會呼叫 `bun update -g`，漏了它其餘各臂會跑到真的 bun
# （更新真實全域套件）。預設只記錄呼叫並成功，完全不做套件操作。
for bup_cmd in git brew claude jq bun; do
    {
        echo '#!/usr/bin/env bash'
        echo "echo \"\$0 \$*\" >> \"$bup/marks/$bup_cmd.log\""
        echo 'exit 0'
    } > "$bup/bin/$bup_cmd"
    chmod +x "$bup/bin/$bup_cmd"
done
echo '{}' > "$bup/dotfiles/claude/settings.json"
echo "# fixture known_hosts" > "$bup/dotfiles/ssh/known_hosts"

bup_make_helpers() {   # $1=失敗的 helper；真實共用 entry 串接真實 guidance/config。
    export BUP_HELPER_FAILURE="$1"
    mkdir -p "$bup/dotfiles/codex/skills/demo" "$bup/dotfiles/claude/skills/demo" "$bup/dotfiles/codex/rules"
    printf '# fixture skill\n' > "$bup/dotfiles/codex/skills/demo/SKILL.md"
    printf '# fixture skill\n' > "$bup/dotfiles/claude/skills/demo/SKILL.md"
    printf 'model = "fixture"\n' > "$bup/dotfiles/codex/config.toml"
    printf '# guidance\n' > "$bup/dotfiles/codex/AGENTS.md"
    cp "$ROOT/scripts/ensure-runtime.sh" "$ROOT/scripts/ensure-runtime-layout.py" "$bup/dotfiles/scripts/"
    for bup_h in ensure-rc-source ensure-lftprc; do
        printf '#!/usr/bin/env bash\necho ran >> "%s"\nexit 0\n' "$bup/marks/${bup_h}.log" > "$bup/dotfiles/scripts/${bup_h}.sh"
    done
    {
        printf '#!/usr/bin/env bash\necho ran >> "%s"\n' "$bup/marks/ensure-codex-guidance.log"
        printf 'exec bash "%s"\n' "$ROOT/scripts/ensure-codex-guidance.sh"
    } > "$bup/dotfiles/scripts/ensure-codex-guidance.sh"
    {
        printf '#!/usr/bin/env python3\nimport pathlib, subprocess, sys\n'
        printf 'pathlib.Path("%s").open("a").write("ran\\n")\n' "$bup/marks/ensure-codex-config.log"
        printf 'sys.exit(subprocess.call([sys.executable, "%s"]))\n' "$ROOT/scripts/ensure-codex-config.py"
    } > "$bup/dotfiles/scripts/ensure-codex-config.py"
    # A correct guidance link is a no-op; remove only this disposable fixture link to test ln failure.
    rm -f "$bup/home/.codex/AGENTS.md"
}
bup_real_ln="$(command -v ln)"
bup_real_yq="$(command -v yq)"
{
    # shellcheck disable=SC2016 # Variables expand in the generated fixture shell.
    printf '#!/usr/bin/env bash\n[ "${BUP_HELPER_FAILURE:-}" = ensure-codex-guidance ] && exit 1\n'
    printf 'exec "%s" "$@"\n' "$bup_real_ln"
} > "$bup/bin/ln"
{
    # shellcheck disable=SC2016 # Variables expand in the generated fixture shell.
    printf '#!/usr/bin/env bash\n[ "${BUP_HELPER_FAILURE:-}" = ensure-codex-config ] && exit 1\n'
    printf 'exec "%s" "$@"\n' "$bup_real_yq"
} > "$bup/bin/yq"
printf '#!/usr/bin/env bash\necho "$$ %s /usr/bin/python3"\n' "$(id -u)" > "$bup/bin/ps"
chmod +x "$bup/bin/ln" "$bup/bin/yq" "$bup/bin/ps"

# Homebrew 自我升級後，第一個 brew 呼叫可能先安裝 portable-ruby；該 bootstrap 的所有進度都
# 寫到 stderr。若第一個呼叫正好是下面刻意吞 stderr 的 `brew trust`，使用者在 pull 之後會看見
# 長時間完全無輸出。stub 只在第一次呼叫印 bootstrap marker，並讓 trust 另印舊版不支援的噪音：
# 前者必須可見，後者仍必須被抑制，才能證明修的是 causal boundary 而非把 redirect 整個拿掉。
cat > "$bup/bin/brew" <<'BREWSTUB'
#!/usr/bin/env bash
n=$(( $(cat "$BREW_BOOTSTRAP_COUNTER" 2>/dev/null || echo 0) + 1 ))
echo "$n" > "$BREW_BOOTSTRAP_COUNTER"
printf '%s\n' "$*" >> "$BREW_BOOTSTRAP_LOG"
if [ "$n" -eq 1 ]; then
    echo 'fixture: portable-ruby bootstrap progress' >&2
fi
if [ "${1:-}" = trust ]; then
    echo 'fixture: legacy brew has no trust command' >&2
    exit 1
fi
exit 0
BREWSTUB
chmod +x "$bup/bin/brew"
export BREW_BOOTSTRAP_COUNTER="$bup/marks/brew-bootstrap-count" \
       BREW_BOOTSTRAP_LOG="$bup/marks/brew-bootstrap.log"

bup_assert_bootstrap_visible() {  # $1=呼叫邊界；$2...=執行命令
    bup_boundary="$1"
    shift
    rm -f "$BREW_BOOTSTRAP_COUNTER" "$BREW_BOOTSTRAP_LOG"
    bup_bootstrap_out="$(DOTFILES_DIR="$bup/dotfiles" HOME="$bup/home" PATH="$bup/bin:$PATH" "$@" 2>&1)"
    bup_bootstrap_rc=$?
    assert_rc "$bup_boundary portable-ruby warm-up → brewup exit 0" 0 "$bup_bootstrap_rc"
    assert_eq "$bup_boundary 第一個 brew 呼叫先 warm-up" "--version" \
        "$(sed -n '1p' "$BREW_BOOTSTRAP_LOG")"
    if grep -q 'fixture: portable-ruby bootstrap progress' <<< "$bup_bootstrap_out"; then
        ok "$bup_boundary portable-ruby bootstrap stderr 對使用者可見"
    else
        bad "$bup_boundary 第一個 brew 呼叫吞掉 portable-ruby bootstrap stderr"
    fi
    if grep -q 'fixture: legacy brew has no trust command' <<< "$bup_bootstrap_out"; then
        bad "$bup_boundary brew trust 的舊版噪音外洩"
    else
        ok "$bup_boundary brew trust 仍抑制舊版不支援噪音"
    fi
}

bup_make_helpers ""
bup_assert_bootstrap_visible "Bash direct" bash "$BUP"
# shellcheck disable=SC2016  # $1 刻意由 `zsh -c` 的子 shell 展開
bup_assert_bootstrap_visible "zsh caller" zsh -c 'exec "$1"' _ "$BUP"

# 還原一般 brew stub，供 18d 其餘 fixtures 記錄呼叫且不帶 bootstrap 輸出。
{
    echo '#!/usr/bin/env bash'
    echo "echo \"\$0 \$*\" >> \"$bup/marks/brew.log\""
    echo 'exit 0'
} > "$bup/bin/brew"
chmod +x "$bup/bin/brew"

# RED 臂：guidance helper 失敗
bup_make_helpers ensure-codex-guidance
bup_out="$(DOTFILES_DIR="$bup/dotfiles" HOME="$bup/home" PATH="$bup/bin:$PATH" bash "$BUP" 2>&1)"
assert_rc "helper 失敗 → brewup 仍 exit 0（不擋套件更新）" 0 $?
if grep -q '⚠️' <<< "$bup_out"; then
    ok "helper 失敗 → 終判印出警告（不誤報完成）"
else
    bad "helper 失敗被靜默——symlink 未更新卻顯示正常完成"
fi
# 失敗不得中斷：下游的 Homebrew 段仍須執行，否則 helper 一失敗就整台不再更新套件
if [ -f "$bup/marks/brew.log" ]; then ok "helper 失敗後下游 brew 段仍執行"; else bad "helper 失敗中斷了後續更新"; fi
for bup_h in ensure-rc-source ensure-codex-guidance ensure-codex-config ensure-lftprc; do
    if [ -f "$bup/marks/${bup_h}.log" ]; then ok "brewup 呼叫了 ${bup_h}"; else bad "brewup 未呼叫 ${bup_h}"; fi
done

bup_make_helpers ensure-codex-config
bup_out="$(DOTFILES_DIR="$bup/dotfiles" HOME="$bup/home" PATH="$bup/bin:$PATH" bash "$BUP" 2>&1)"; bup_rc=$?
assert_rc "config 失敗經共用 entry → brewup 仍 exit 0" 0 "$bup_rc"
if grep -q '⚠️' <<< "$bup_out"; then ok "config 失敗經共用 entry 對使用者可見"; else bad "config 失敗被共用 entry 吞掉"; fi

# pull 換掉 brewup.sh 自己 → 必須用新版重跑。執行中的 bash 會繼續跑舊內容（git 是 unlink +
# 新建，process 握著舊 inode），不重跑的話「pull 進新版、卻用舊版跑完這一輪」，本次新增的
# pull 後段動作全部延後一個週期且無聲。實地觸發過（落後的 MacBook 要跑兩次才部署到 helper）。
rm -f "$bup/marks/"*.log
bup_make_helpers ""
cp "$BUP" "$bup/self.sh"
# git stub 在 pull 時把「本腳本」換掉，模擬 pull 帶進新版。
# **必須 rm 之後再寫（unlink + 新建）**——那才是 git checkout 的實際行為，正在執行的 process
# 握著舊 inode、會把舊內容跑完。若改成 `>` 原地截斷（同 inode），正在跑的 bash 從舊 offset
# 讀到 EOF 會**整支靜默中止**，那是另一種失效、不是這裡要模擬的情境（2026-08-09 實測分辨）。
# stub 每次 pull 都讓 self.sh 換一個新 checksum，且**換上去的仍是 brewup.sh 本身**——
# 迴圈防護若失效，子行程會再偵測到變更、再 exec，無限下去。用「換成惰性 stub」測不出這件事
# （那種替身不會再重跑，有沒有防護結果都一樣＝虛設斷言）。
cat > "$bup/bin/git" <<'GITSTUB'
#!/usr/bin/env bash
echo "$0 $*" >> "$GIT_STUB_LOG"
if [ "$1" = pull ]; then
    n=$(( $(cat "$GIT_STUB_COUNTER" 2>/dev/null || echo 0) + 1 ))
    echo "$n" > "$GIT_STUB_COUNTER"
    # 封頂：迴圈防護失效時要能自然收斂，不能讓測試掛死。
    # 不用 `timeout` —— macOS 沒有它（實測 `command -v timeout gtimeout` 皆空），
    # 依賴它會讓整段變成 exit 127 的假紅／假綠。
    if [ "$n" -le 5 ]; then
        rm -f "$GIT_STUB_SELF"
        { cat "$GIT_STUB_SRC"; echo "# pull-generation $n"; } > "$GIT_STUB_SELF"
        chmod +x "$GIT_STUB_SELF"
    fi
fi
exit 0
GITSTUB
chmod +x "$bup/bin/git"
export GIT_STUB_LOG="$bup/marks/git.log" GIT_STUB_SELF="$bup/self.sh" \
       GIT_STUB_SRC="$BUP" GIT_STUB_COUNTER="$bup/marks/gen"
bup_out="$(DOTFILES_DIR="$bup/dotfiles" HOME="$bup/home" PATH="$bup/bin:$PATH" bash "$bup/self.sh" 2>&1)"
bup_rc=$?
assert_rc "自身被 pull 換掉 → exit 0" 0 "$bup_rc"
# 迴圈防護生效時剛好 pull 兩次：父行程一次、重跑的子行程一次
assert_eq "只重跑一次（迴圈防護；否則 pull 次數會失控）" 2 "$(cat "$bup/marks/gen" 2>/dev/null || echo 0)"
bup_reexec_n=$(grep -c '↻' <<< "$bup_out") || bup_reexec_n=0
if [ "$bup_reexec_n" -eq 1 ]; then
    ok "偵測到自身更新並用新版重跑，且明確告知一次"
else
    bad "重跑次數異常（↻ 出現 ${bup_reexec_n} 次）——0＝沿用舊版跑完（新增的 pull 後段動作延後一週期且無聲）"
fi
# 還原 git stub 供後續斷言
cat > "$bup/bin/git" <<'GITSTUB2'
#!/usr/bin/env bash
echo "$0 $*" >> "$GIT_STUB_LOG"
exit 0
GITSTUB2
chmod +x "$bup/bin/git"

# GREEN 臂：全部成功 → 不得出現警告（否則警告變雜訊、下次真失敗時沒人看）
rm -f "$bup/marks/"*.log
bup_make_helpers ""
bup_out="$(DOTFILES_DIR="$bup/dotfiles" HOME="$bup/home" PATH="$bup/bin:$PATH" bash "$BUP" 2>&1)"
assert_rc "全部成功 → exit 0" 0 $?
if grep -q '⚠️' <<< "$bup_out"; then bad "全部成功卻仍印警告"; else ok "全部成功 → 無警告"; fi

# 隔離自證：cp 落在沙盒 HOME，真實 $HOME/.ssh/known_hosts 一個 byte 未動
if [ -f "$bup/home/.ssh/known_hosts" ]; then ok "known_hosts 寫進沙盒 HOME"; else bad "known_hosts 未寫進沙盒——隔離可能失效"; fi
if [ -n "$bup_real_kh_sum" ]; then
    assert_eq "真實 \$HOME/.ssh/known_hosts 未被觸碰" "$bup_real_kh_sum" "$(cksum < "$bup_real_home/.ssh/known_hosts")"
else
    ok "真實 \$HOME 無 known_hosts（無可觸碰之物）"
fi

# --- 第 6 節：bun 全域套件更新（真實命令以 stub 隔離）-------------------
# 精確驗證只呼叫一次 update -g；不得先 outdated 查詢、重試或加 --latest。
export BUP_BUN_FIXTURE="$bup"
bup_make_bun() {   # $1=stdout；$2=stderr；$3=exit code（預設 0）
    printf '%s\n' "$1" > "$bup/bun-output.txt"
    printf '%s\n' "$2" > "$bup/bun-error.txt"
    printf '%s\n' "${3:-0}" > "$bup/bun-rc.txt"
    : > "$bup/marks/bun.log"
    cat > "$bup/bin/bun" <<'BUNSTUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$BUP_BUN_FIXTURE/marks/bun.log"
if [ "$#" -ne 2 ] || [ "$1" != update ] || [ "$2" != -g ]; then
    echo 'fixture: unexpected bun command' >&2
    exit 64
fi
cat "$BUP_BUN_FIXTURE/bun-output.txt"
cat "$BUP_BUN_FIXTURE/bun-error.txt" >&2
exit "$(cat "$BUP_BUN_FIXTURE/bun-rc.txt")"
BUNSTUB
    chmod +x "$bup/bin/bun"
}
bup_run_bun() {    # 跑一次 brewup，回傳輸出
    DOTFILES_DIR="$bup/dotfiles" HOME="$bup/home" PATH="$bup/bin:$PATH" bash "$BUP" 2>&1
}
bup_make_helpers ""

# A. 已安裝 bun → 直接更新，讓使用者看得到原生命令輸出。
bup_make_bun 'fixture: bun global packages updated' ''
bup_out="$(bup_run_bun)"
assert_rc "bun 更新成功 → brewup exit 0" 0 $?
assert_eq "bun 已安裝 → 只執行一次 update -g" "update -g" "$(cat "$bup/marks/bun.log")"
if grep -q 'fixture: bun global packages updated' <<< "$bup_out"; then
    ok "bun 更新 stdout 對使用者可見"
else
    bad "bun 更新 stdout 被吞掉"
fi
if grep -q '⚠️' <<< "$bup_out"; then
    bad "bun 更新成功卻印失敗警告"
else
    ok "bun 更新成功 → 無失敗警告"
fi

# B. 網路／registry／全域 package.json 問題 → 原錯誤與警告可見，保留 exit 0。
bup_make_bun '' 'fixture: bun registry unavailable' 42
bup_out="$(bup_run_bun)"
assert_rc "bun 更新失敗 → brewup 仍 exit 0" 0 $?
assert_eq "bun 更新失敗 → 只嘗試一次 update -g" "update -g" "$(cat "$bup/marks/bun.log")"
if grep -q 'fixture: bun registry unavailable' <<< "$bup_out"; then
    ok "bun 更新失敗 stderr 對使用者可見"
else
    bad "bun 更新失敗 stderr 被吞掉"
fi
if grep -q '⚠️  bun 全域套件更新失敗' <<< "$bup_out"; then
    ok "bun 更新失敗 → 明確警告"
else
    bad "bun 更新失敗卻無明確警告"
fi

# C. 完全沒有 bun → 整段跳過；PATH 收窄，確保找不到真的 bun。
rm -f "$bup/bin/bun"
bup_out="$(DOTFILES_DIR="$bup/dotfiles" HOME="$bup/home" PATH="$bup/bin:/usr/bin:/bin" bash "$BUP" 2>&1)"
assert_rc "無 bun → brewup 仍 exit 0" 0 $?
if grep -q 'bun' <<< "$bup_out"; then
    bad "無 bun 卻仍輸出 bun 相關訊息"
else
    ok "無 bun → 整段靜默跳過"
fi

# all-up.sh 以 `[ -x "$BREWUP" ]` 決定要直接跑腳本還是退回 `zsh -ic "brewup"`（互動 alias 路徑，
# 正是當初為了消掉 job control 雜訊而繞開的那條，且在 rc 尚未清理的機器上會跑到不含 helper 的舊
# alias）。執行位是個容易在編輯檔案時靜默掉的屬性——2026-08-09 實地掉過一次，故釘住。
for xbit_script in scripts/brewup.sh scripts/sysup.sh; do
    if [ -x "$ROOT/$xbit_script" ]; then
        ok "$xbit_script 保有執行位（all-up 的 -x 分支才走得到）"
    else
        bad "$xbit_script 失去執行位——allup 會退回互動 alias fallback"
    fi
done

# Setup AI CLI selection and install failure propagation are covered by
# dev-environment. Antigravity is now opt-in (D-20261009-setup-tool-ownership).
echo "▶ 18d2. brewup 保留 cask 自行更新邊界"
if grep -q -- '--greedy' "$ROOT/scripts/brewup.sh"; then
    bad "brewup 不得為 auto_updates cask 強制加入 --greedy"
else
    ok "brewup 維持不強制更新 auto_updates cask"
fi

echo "▶ 18e. ensure-ssh-config.sh 幂等重生 ~/.ssh/config（原子寫入 + 完整性驗證）"
ESC="$ROOT/scripts/ensure-ssh-config.sh"
esc="$TMP/esc"
mkdir -p "$esc/src" "$esc/home"
printf 'Host example\n  User demo\n' > "$esc/src/config"

esc_run() { SOURCE_FILE="$esc/src/config" TARGET_HOME="$1" BACKUP_ROOT="$esc/backup" bash "$ESC"; }

esc_out="$(esc_run "$esc/home")"; esc_rc=$?
assert_rc "首次部署 → exit 0" 0 "$esc_rc"
if [ -f "$esc/home/.ssh/config" ]; then ok "config 已產生"; else bad "config 未產生"; fi
# stat -c 先試（GNU rc=0、BSD rc=1）再退 -f，順序不可顛倒——同 :3758 與
# codex-runtime-hygiene.sh 的既有註解。**2026-08-14 首次在 Linux 跑完整測試才發現這裡寫反了。**
#
# ⚠️ 失效機制與 :3758 那條註解描述的**不完全相同**，值得分清楚：
#   - `%m` 那種**有效**的 filesystem 格式 → GNU `stat -f` 真的成功，`||` 永不觸發（:3758 的情形）。
#   - `%Lp` 這種**無效**格式 → GNU `stat -f` 其實回 rc=1，`||` **有**觸發；但它在失敗前已經把
#     一整段 filesystem 統計吐到 stdout，於是 command substitution 收到的是「那段 ＋ 600」相連。
#   兩者後果相同（fallback 的輸出被污染），但別把後者也記成「假成功」。
# **危害不是這條紅，是它會掩蓋往後所有真失敗**——在 Linux 上看到 FAIL=1 會先被當成已知的那條。
assert_eq "權限 600" "600" "$(stat -c '%a' "$esc/home/.ssh/config" 2>/dev/null || stat -f '%Lp' "$esc/home/.ssh/config" 2>/dev/null)"
if grep -q 'Host example' "$esc/home/.ssh/config"; then ok "來源內容已灌入"; else bad "來源內容遺失"; fi
# config.local 是 setup 的職責——這裡先生一個空檔會讓 setup 的 `[ ! -f ]` 永遠跳過真內容
if [ -e "$esc/home/.ssh/config.local" ]; then bad "不該建立 config.local（會讓 setup 跳過真內容）"; else ok "不建立 config.local"; fi

esc_out="$(esc_run "$esc/home")"
assert_rc "二次跑 → exit 0" 0 $?
assert_eq "內容相同時靜默（無輸出，避免每次 brewup 都噪音）" "" "$esc_out"

printf 'Host example\n  User demo2\n' > "$esc/src/config"
esc_out="$(esc_run "$esc/home")"
if grep -q 'demo2' "$esc/home/.ssh/config"; then ok "來源變更 → 重生"; else bad "來源變更未反映"; fi

# 既有「非本腳本產生」的手寫 config：必須先備份才接管
mkdir -p "$esc/handwritten/.ssh"
printf '# my own config\nHost secret\n' > "$esc/handwritten/.ssh/config"
esc_run "$esc/handwritten" >/dev/null
assert_rc "接管手寫 config → exit 0" 0 $?
if grep -rq 'my own config' "$esc/backup" 2>/dev/null; then ok "手寫 config 已備份"; else bad "手寫 config 未備份即被覆蓋"; fi
if grep -q 'Host example' "$esc/handwritten/.ssh/config"; then ok "接管後內容為 dotfiles 版"; else bad "接管失敗"; fi
# 本腳本產生的檔不得每次都再備份一次——否則備份目錄無限膨脹、真正的手寫檔淹沒其中
esc_backup_n="$(find "$esc/backup" -type f | wc -l | tr -d ' ')"
printf 'Host example\n  User demo3\n' > "$esc/src/config"
esc_run "$esc/handwritten" >/dev/null
assert_eq "已受管的檔重生時不再備份" "$esc_backup_n" "$(find "$esc/backup" -type f | wc -l | tr -d ' ')"

# 來源缺席 → 早退且不建檔（新機器 clone 前、或路徑打錯時不得留半成品）
mkdir -p "$esc/nosrc"
SOURCE_FILE="$esc/src/missing" TARGET_HOME="$esc/nosrc" BACKUP_ROOT="$esc/backup" bash "$ESC" >/dev/null 2>&1
assert_rc "來源缺席 → exit 0（早退）" 0 $?
if [ -e "$esc/nosrc/.ssh/config" ]; then bad "來源缺席仍建了檔"; else ok "來源缺席不建檔"; fi

# 產出不完整（來源讀不到）→ 原檔一個 byte 都不能動。原本的行內版是 `> ~/.ssh/config`
# 直接截斷寫入，這種情況會留下殘缺的 config，而殘缺的 ssh config 正是「連得上但認錯身分」
# 那類最難查的故障。
esc_before="$(cksum < "$esc/home/.ssh/config")"
chmod 000 "$esc/src/config"
esc_out="$(SOURCE_FILE="$esc/src/config" TARGET_HOME="$esc/home" BACKUP_ROOT="$esc/backup" bash "$ESC" 2>&1)"
esc_rc=$?
chmod 644 "$esc/src/config"
assert_rc "產出不完整 → exit 1" 1 "$esc_rc"
# 兩道防線任一先攔到都可以（cat 失敗 / bytes 不符），但**不得靜默**——
# 靜默失敗會讓 dotsync 的 helper warn 有理由、使用者卻看不到是哪一項壞了
if grep -q '⚠️' <<< "$esc_out"; then ok "失敗有明確訊息"; else bad "失敗卻靜默"; fi
assert_eq "不完整時原檔未動" "$esc_before" "$(cksum < "$esc/home/.ssh/config")"
if find "$esc/home/.ssh" -name '.config.dotfiles.*' | grep -q .; then bad "殘留暫存檔"; else ok "暫存檔已清"; fi

# key 檔名落後的機器：拿「可用的舊 config」換成「指向不存在的 key」＝當場斷認證，
# 而修正要靠 GitHub 拉回來。本 helper 讓重生變自動，這道守門是配套。
mkdir -p "$esc/legacy/.ssh"
printf 'Host github.com\n  IdentityFile ~/.ssh/id_old\n' > "$esc/legacy/.ssh/config"
touch "$esc/legacy/.ssh/id_old"
printf 'Host github.com\n  IdentityFile ~/.ssh/id_new\n' > "$esc/src/config"
esc_before="$(cksum < "$esc/legacy/.ssh/config")"
esc_out="$(SOURCE_FILE="$esc/src/config" TARGET_HOME="$esc/legacy" BACKUP_ROOT="$esc/backup" bash "$ESC" 2>&1)"
assert_rc "新 config 的 key 缺席且舊 key 仍在 → 拒絕（exit 1）" 1 $?
assert_eq "拒絕時原 config 一個 byte 未動" "$esc_before" "$(cksum < "$esc/legacy/.ssh/config")"
if grep -q 'id_new' <<< "$esc_out"; then ok "訊息點名缺席的 key"; else bad "沒說是哪一把 key 缺席"; fi
if grep -q 'cp' <<< "$esc_out"; then ok "訊息給出處置（cp 不 mv）"; else bad "訊息無處置指引"; fi
# 補上新 key 之後就該放行——守門不能變成永久卡死
touch "$esc/legacy/.ssh/id_new"
SOURCE_FILE="$esc/src/config" TARGET_HOME="$esc/legacy" BACKUP_ROOT="$esc/backup" bash "$ESC" >/dev/null 2>&1
assert_rc "補上新 key 後放行" 0 $?
if grep -q 'id_new' "$esc/legacy/.ssh/config"; then ok "放行後已換成新 config"; else bad "放行後未更新"; fi
# 全新機器（尚無 config、也還沒放 key）不得被自己擋住——否則 setup 首跑就死在這裡
mkdir -p "$esc/fresh"
SOURCE_FILE="$esc/src/config" TARGET_HOME="$esc/fresh" BACKUP_ROOT="$esc/backup" bash "$ESC" >/dev/null 2>&1
assert_rc "全新機器（無既有 config）照常部署" 0 $?
if [ -f "$esc/fresh/.ssh/config" ]; then ok "全新機器有拿到 config"; else bad "全新機器被守門擋住"; fi
printf 'Host example\n  User demo3\n' > "$esc/src/config"

# 五個消費端都必須改呼叫 helper，且行內複本要真的消失——留一份沒改就會漂移
for esc_wiring in setup-mac-env.sh setup-linux-env.sh scripts/dotfiles-sync.sh scripts/brewup.sh scripts/add-new-host.sh; do
    if grep -q 'ensure-ssh-config.sh' "$ROOT/$esc_wiring"; then
        ok "$esc_wiring 已接上 ssh-config helper"
    else
        bad "$esc_wiring 未接上 ssh-config helper"
    fi
    if grep -q '} > ~/.ssh/config' "$ROOT/$esc_wiring"; then
        bad "$esc_wiring 仍留著行內生成複本（dedup 未完成）"
    else
        ok "$esc_wiring 行內複本已移除"
    fi
done
# dotfiles-sync 需本機段與遠端段都呼叫，否則遠端主機的 config 從此不再更新。
# 數「實際呼叫」而非「提及」——註解也會寫到腳本名，光數字面會把註解算進去。
assert_eq "dotfiles-sync 本機+遠端兩處都呼叫 ssh-config helper" 2 \
    "$(grep -c 'bash .*ensure-ssh-config.sh' "$ROOT/scripts/dotfiles-sync.sh")"


echo "▶ 22. brewup / sysup / brewfix（rc alias 抽成腳本後的三個入口）"

# --- sysup.sh 平台 guard ---
SYSUP_SH="$ROOT/scripts/sysup.sh"
SYSUP_UNAME=Darwin bash "$SYSUP_SH" >/dev/null 2>&1
assert_rc "sysup 於非 Linux → exit 2（不觸碰 apt）" 2 $?

# --- brewfix.sh ---
BFX="$ROOT/scripts/brewfix.sh"
bfx="$TMP/bfx"; mkdir -p "$bfx/Caskroom" "$bfx/bin"

# stub：預設「無 brew prefix 底下的 process」
cat > "$bfx/ps-empty" <<'STUB'
#!/usr/bin/env bash
echo "  501 /usr/sbin/unrelated"
STUB
# stub：一個位於 brew prefix 底下、lsof 條目極少（＝一個 dylib 都沒載入）的 process
cat > "$bfx/ps-stuck" <<'STUB'
#!/usr/bin/env bash
printf '%s %s\n' 99999 "__PREFIX__/Caskroom/codex/1.0/bin/codex"
STUB
sed -i.bak "s|__PREFIX__|$bfx|" "$bfx/ps-stuck" && rm -f "$bfx/ps-stuck.bak"
cat > "$bfx/lsof-few" <<'STUB'
#!/usr/bin/env bash
printf 'a\nb\nc\nd\ne\nf\ng\n'
STUB
cat > "$bfx/lsof-many" <<'STUB'
#!/usr/bin/env bash
for i in $(seq 1 60); do echo "line$i"; done
STUB
cat > "$bfx/killall-stub" <<'STUB'
#!/usr/bin/env bash
echo "killall $*" >> "$KILLALL_LOG"
STUB
cat > "$bfx/sudo-stub" <<'STUB'
#!/usr/bin/env bash
[ "${1:-}" = "-n" ] && exit 0     # 佯裝免密 sudo 可用
shift 0; exec "$@"
STUB
chmod +x "$bfx"/ps-* "$bfx"/lsof-* "$bfx"/killall-stub "$bfx"/sudo-stub

bfx_env() {
    BREWFIX_UNAME=Darwin BREWFIX_BREW_PREFIX="$bfx" BREWFIX_CASKROOM="$bfx/Caskroom" \
    BREWFIX_PS="$1" BREWFIX_LSOF="$2" BREWFIX_KILLALL="$bfx/killall-stub" \
    BREWFIX_SUDO="$bfx/sudo-stub" KILLALL_LOG="$bfx/killall.log" bash "$BFX" "${3:-}"
}

# 非 macOS → exit 2
BREWFIX_UNAME=Linux bash "$BFX" >/dev/null 2>&1
assert_rc "非 macOS → exit 2" 2 $?

# 未知參數 → exit 2（不得被當成 --fix）
BREWFIX_UNAME=Darwin bash "$BFX" --wipe >/dev/null 2>&1
assert_rc "未知參數 → exit 2" 2 $?

# Caskroom 不存在 → exit 2
BREWFIX_UNAME=Darwin BREWFIX_BREW_PREFIX="$bfx" BREWFIX_CASKROOM="$bfx/nope" bash "$BFX" >/dev/null 2>&1
assert_rc "Caskroom 不存在 → exit 2" 2 $?

# 乾淨 → CLEAN / exit 0
out=$(bfx_env "$bfx/ps-empty" "$bfx/lsof-many"); rc=$?
assert_rc "無殘留無卡死 → exit 0" 0 $rc
assert_eq "verdict: CLEAN" "verdict: CLEAN" "$(echo "$out" | grep '^verdict:')"

# 有 *.upgrading 殘留 → RESIDUE / exit 1，且唯讀模式**不得刪除**
mkdir -p "$bfx/Caskroom/codex/0.1.upgrading"
out=$(bfx_env "$bfx/ps-empty" "$bfx/lsof-many"); rc=$?
assert_rc "有殘留 → exit 1" 1 $rc
assert_eq "verdict: RESIDUE" "verdict: RESIDUE" "$(echo "$out" | grep '^verdict:')"
if [ -d "$bfx/Caskroom/codex/0.1.upgrading" ]; then ok "唯讀模式未刪除殘留"; else bad "唯讀模式竟刪除了殘留"; fi

# --fix → 清除殘留並複驗 CLEAN
out=$(bfx_env "$bfx/ps-empty" "$bfx/lsof-many" --fix); rc=$?
assert_rc "--fix 清完 → exit 0" 0 $rc
if [ ! -d "$bfx/Caskroom/codex/0.1.upgrading" ]; then ok "--fix 已清除殘留"; else bad "--fix 未清除殘留"; fi

# 無卡死 process 時不得驚動 syspolicyd（killall 是全系統動作，不該無謂執行）
if [ ! -s "$bfx/killall.log" ]; then ok "無卡死 process → 不呼叫 killall"; else bad "無卡死卻呼叫了 killall"; fi

# 卡死 process（lsof 條目極少）→ STUCK
out=$(bfx_env "$bfx/ps-stuck" "$bfx/lsof-few"); rc=$?
assert_rc "偵測到卡死 process → exit 1" 1 $rc
assert_eq "verdict: STUCK" "verdict: STUCK" "$(echo "$out" | grep '^verdict:')"
if echo "$out" | grep -q '^stuck-process: pid=99999'; then ok "列出卡死 pid"; else bad "未列出卡死 pid"; fi

# 同一個 process，但 lsof 條目正常（dylib 已載入）→ 不得判為卡死
out=$(bfx_env "$bfx/ps-stuck" "$bfx/lsof-many"); rc=$?
assert_rc "lsof 條目正常 → 不誤判為卡死（exit 0）" 0 $rc
assert_eq "verdict: CLEAN（正常執行中的 process）" "verdict: CLEAN" "$(echo "$out" | grep '^verdict:')"

# --fix 遇卡死 → 才呼叫 killall syspolicyd
: > "$bfx/killall.log"
bfx_env "$bfx/ps-stuck" "$bfx/lsof-few" --fix >/dev/null 2>&1
if grep -q 'killall syspolicyd' "$bfx/killall.log"; then ok "--fix 遇卡死 → 呼叫 killall syspolicyd"; else bad "--fix 遇卡死卻未呼叫 killall"; fi

# 破壞性刪除的作用域：Caskroom 外的 *.upgrading 不得被碰
outside="$TMP/outside.upgrading"; mkdir -p "$outside"
mkdir -p "$bfx/Caskroom/tool/9.9.upgrading"
bfx_env "$bfx/ps-empty" "$bfx/lsof-many" --fix >/dev/null 2>&1
if [ -d "$outside" ]; then ok "Caskroom 外的 *.upgrading 未被觸碰"; else bad "誤刪了 Caskroom 外的目錄"; fi
if [ ! -d "$bfx/Caskroom/tool/9.9.upgrading" ]; then ok "Caskroom 內殘留已清"; else bad "Caskroom 內殘留未清"; fi

echo "▶ 23. migrate-github-remotes.sh（GitHub 多身分收斂的遷移入口）"
# 這支要在 12 台機器上各跑一次，且它會**改每個 repo 的 remote**——錯一次的代價是那台機器
# 所有 repo 一起連不上。三件事必須守住：身分驗證是硬前提（順序錯就把錯誤身分固化）、
# dry-run 真的零 mutation、非 origin 的 remote 不能漏（實跑工作 mac 時就有兩條 fork remote）。
MG_SCRIPT="$ROOT/scripts/migrate-github-remotes.sh"
mg="$TMP/mg"; mkdir -p "$mg/roots"
export GIT_CONFIG_GLOBAL="$mg/gitconfig"   # 隔離：絕不能碰使用者真的 ~/.gitconfig
: > "$GIT_CONFIG_GLOBAL"

# ssh stub：認到正確身分
cat > "$mg/ssh-ok" <<'MGEOF'
#!/usr/bin/env bash
for a in "$@"; do
    case "$a" in
        git@github.com) echo "Hi jjshen-eland! You've successfully authenticated"; exit 1 ;;
        git@github-me)  echo "Hi dev-bitpod-cc! You've successfully authenticated"; exit 1 ;;
    esac
done
echo "unexpected: $*"; exit 1
MGEOF
# ssh stub：**連得上但認到錯帳號**——IdentitiesOnly 沒設時的真實長相，正是 gate 要擋的
cat > "$mg/ssh-wrong" <<'MGEOF'
#!/usr/bin/env bash
echo "Hi dev-bitpod-cc! You've successfully authenticated"; exit 1
MGEOF
chmod +x "$mg/ssh-ok" "$mg/ssh-wrong"

mg_mkrepo() {   # $1=名字 $2=origin url [$3=額外 remote 名 $4=額外 url]
    local d="$mg/roots/$1"
    git init -q -b main "$d"
    git -C "$d" remote add origin "$2"
    [ $# -ge 4 ] && git -C "$d" remote add "$3" "$4"
}
mg_reset() {
    rm -rf "$mg/roots"; mkdir -p "$mg/roots"
    mg_mkrepo work-a  "git@github-work:elandcomtw/krepo.git"
    mg_mkrepo work-b  "git@github-work:elandinfo/biz-chat.git" fork "git@github-work:elandinfo/fork-biz-chat"
    mg_mkrepo mine    "git@github.com:dev-bitpod-cc/isdotgd.git"
    mg_mkrepo other   "https://gitlab.internal/iac/thing.git"
}
mg_url() { git -C "$mg/roots/$1" remote get-url "${2:-origin}"; }

# 身分認到錯帳號 → STOP 且零 mutation
mg_reset
MIGRATE_SSH="$mg/ssh-wrong" "$MG_SCRIPT" --apply "$mg/roots" >/dev/null 2>&1
assert_rc "身分認到錯帳號 → exit 1（STOP）" 1 $?
assert_eq "STOP 時零 mutation（remote 原封不動）" \
    "git@github-work:elandcomtw/krepo.git" "$(mg_url work-a)"

# dry-run：印計畫、零 mutation
out="$(MIGRATE_SSH="$mg/ssh-ok" "$MG_SCRIPT" "$mg/roots")"
assert_rc "dry-run → exit 0" 0 $?
if grep -q '^would-change: ' <<< "$out"; then ok "dry-run 印出換寫計畫"; else bad "dry-run 未印計畫（${out}）"; fi
assert_eq "dry-run 零 mutation" "git@github-work:elandcomtw/krepo.git" "$(mg_url work-a)"
if grep -q 'dry-run' <<< "$out"; then ok "dry-run 明示未執行"; else bad "dry-run 未告知這只是計畫"; fi

# --apply：三種換寫都對，不該動的不動
out="$(MIGRATE_SSH="$mg/ssh-ok" "$MG_SCRIPT" --apply "$mg/roots")"
assert_rc "--apply → exit 0" 0 $?
assert_eq "github-work → 標準 github.com" "git@github.com:elandcomtw/krepo.git" "$(mg_url work-a)"
assert_eq "個人 repo → github-me"          "git@github-me:dev-bitpod-cc/isdotgd.git" "$(mg_url mine)"
assert_eq "非 GitHub 的 remote 不得被碰"   "https://gitlab.internal/iac/thing.git"   "$(mg_url other)"
# 本次的重點：spec 那段手貼迴圈只掃 origin，工作 mac 上就有兩條 fork remote 會被留下
assert_eq "非 origin 的 remote 同樣換寫"   "git@github.com:elandinfo/fork-biz-chat"  "$(mg_url work-b fork)"

# 幂等：再跑一次應無事可做
out="$(MIGRATE_SSH="$mg/ssh-ok" "$MG_SCRIPT" --apply "$mg/roots")"
if grep -q '需換寫 0' <<< "$out"; then ok "--apply 幂等（第二次無事可做）"; else bad "重跑仍有換寫（${out}）"; fi

# insteadOf：只清 github-work 那幾條，使用者其他的改寫規則不得被波及
git config --global "url.git@github-work:elandcomtw/.insteadOf" "git@github.com:elandcomtw/"
git config --global "url.git@internal-mirror/.insteadOf" "https://internal/"
MIGRATE_SSH="$mg/ssh-ok" "$MG_SCRIPT" --apply "$mg/roots" >/dev/null 2>&1
if ! git config --global --get-regexp 'insteadof' 2>/dev/null | grep -q 'github-work'; then ok "github-work 的 insteadOf 已清"; else bad "insteadOf 未清（收斂沒完成）"; fi
if git config --global --get-regexp 'insteadof' 2>/dev/null | grep -q 'internal-mirror'; then ok "無關的 insteadOf 未被波及"; else bad "誤刪了使用者其他的 insteadOf"; fi

# --skip-identity-check：明說才跳過（stub 給錯身分也照跑）
mg_reset
MIGRATE_SSH="$mg/ssh-wrong" "$MG_SCRIPT" --apply --skip-identity-check "$mg/roots" >/dev/null 2>&1
assert_rc "--skip-identity-check → 跳過 gate、exit 0" 0 $?
assert_eq "跳過 gate 後仍正常換寫" "git@github.com:elandcomtw/krepo.git" "$(mg_url work-a)"

# 未知選項 → exit 2（**不得**被當成路徑或靜默忽略：那會讓 --aply 這種打錯字變成
# 「掃了整個 $HOME、什麼都沒做」而使用者以為跑過了）
"$MG_SCRIPT" --aply "$mg/roots" >/dev/null 2>&1
assert_rc "未知選項 → exit 2" 2 $?

unset GIT_CONFIG_GLOBAL

echo "▶ 23b. dotfiles remote 一次性遷移已退役"
# 2026-08-15 的 owner 遷移已在全機隊收斂；steady-state 更新路徑不得再攜帶一次性
# mutation helper。這個 gate 防止腳本或呼叫點日後被誤帶回 brewup / dotsync。
if [ ! -e "$ROOT/scripts/ensure-dotfiles-remote.sh" ]; then
    ok "一次性 remote migration helper 已移除"
else
    bad "一次性 remote migration helper 仍存在"
fi
if ! grep -Fq 'ensure-dotfiles-remote.sh' \
    "$ROOT/scripts/brewup.sh" "$ROOT/scripts/dotfiles-sync.sh"; then
    ok "steady-state 更新路徑沒有 remote migration 呼叫"
else
    bad "steady-state 更新路徑仍引用 remote migration helper"
fi

echo "▶ 23c. setup-git-identity.sh（機器層 git 身分 ＋ 目錄分界）"
# 這套設計的價值全在「分界外會不會被擋下」那一格。擋不下來的失敗是**靜默的**：git 直接用
# `<user>@<hostname>` 捏造作者送出，本 repo 歷史那筆 `jjshen@jjshen-mba.local` 就是這樣來的。
# 所以下面每一組都用真的 git repo 去問 `git var GIT_AUTHOR_IDENT`，不看設定檔長相。
SGI_SCRIPT="$ROOT/scripts/setup-git-identity.sh"
sgi="$TMP/sgi"; mkdir -p "$sgi"
# $1=sandbox home 路徑；$2=legacy 時在 ~/.gitconfig 寫死身分（12 台機器的真實長相）
sgi_mkhome() {
    local h="$1"
    mkdir -p "$h/.dotfiles/git"
    cp "$ROOT/git/config" "$h/.dotfiles/git/config"
    if [ "${2:-}" = legacy ]; then
        # 寫死身分排在 [include] **之前**——順序照抄機隊現況，因為它決定誰贏
        printf '[user]\n\tname = legacy\n\temail = legacy@example.com\n[include]\n\tpath = ~/.dotfiles/git/config\n' > "$h/.gitconfig"
    else
        printf '[include]\n\tpath = ~/.dotfiles/git/config\n' > "$h/.gitconfig"
    fi
    mkdir -p "$h/Projects/repo-a" "$h/SideProjects/repo-b" "$h/Elsewhere/repo-c"
    local d
    for d in Projects/repo-a SideProjects/repo-b Elsewhere/repo-c .dotfiles; do git init -q -b main "$h/$d"; done
}
sgi_run()   { local h="$1"; shift; HOME="$h" "$SGI_SCRIPT" "$@" </dev/null; }
sgi_ident() { local h="$1"; HOME="$h" git -C "$h/$2" var GIT_AUTHOR_IDENT 2>&1; }

# ---- 主沙盒：有 legacy 寫死身分 ----
sgi_mkhome "$sgi/home" legacy

# 收斂前：分界外用的是那個寫死值——**這正是要消滅的「能動但錯了」**，先把它釘成事實
if grep -q 'legacy@example.com' <<< "$(sgi_ident "$sgi/home" Elsewhere/repo-c)"; then
    ok "收斂前：分界外安靜地用寫死身分（本測試的存在理由）"
else
    bad "前提不成立：分界外未取用寫死身分（$(sgi_ident "$sgi/home" Elsewhere/repo-c)）"
fi

# dry-run：印計畫、零 mutation
sgi_out="$(sgi_run "$sgi/home" --name tester --work-email w@example.com --personal-email p@example.com)"
assert_rc "dry-run → exit 0" 0 $?
if grep -q 'dry-run' <<< "$sgi_out"; then ok "dry-run 明示未執行"; else bad "dry-run 未告知這只是計畫"; fi
if [ -e "$sgi/home/.gitconfig-work" ]; then bad "dry-run 竟寫了身分檔"; else ok "dry-run 零 mutation（未寫身分檔）"; fi
if grep -q 'legacy@example.com' "$sgi/home/.gitconfig"; then ok "dry-run 未動 ~/.gitconfig"; else bad "dry-run 動了 ~/.gitconfig"; fi

# 未知參數 → exit 2（不得被靜默忽略，否則打錯字會變成「跑過了但什麼都沒設」）
sgi_run "$sgi/home" --aply >/dev/null 2>&1
assert_rc "未知參數 → exit 2" 2 $?

# --apply：寫兩檔 ＋ 清掉寫死身分 ＋ 留備份
sgi_run "$sgi/home" --apply --name tester --work-email w@example.com --personal-email p@example.com >/dev/null 2>&1
assert_rc "--apply → exit 0" 0 $?
assert_eq "work 身分檔權限 600" "600" \
    "$(stat -c '%a' "$sgi/home/.gitconfig-work" 2>/dev/null || stat -f '%Lp' "$sgi/home/.gitconfig-work" 2>/dev/null)"
assert_eq "personal 身分檔權限 600" "600" \
    "$(stat -c '%a' "$sgi/home/.gitconfig-personal" 2>/dev/null || stat -f '%Lp' "$sgi/home/.gitconfig-personal" 2>/dev/null)"
# 寫死身分必須消失。留著它，分界外就會繼續安靜地用它——分界等於沒做
if grep -q 'legacy@example.com' "$sgi/home/.gitconfig"; then bad "寫死身分未移除（分界外仍會用它）"; else ok "寫死身分已移除"; fi
if ls "$sgi/home"/.gitconfig.bak.* >/dev/null 2>&1; then ok "移除前留下備份"; else bad "未備份就改 ~/.gitconfig"; fi

# 三個分界各自解析對，且**互不污染**
# shellcheck disable=SC2088  # 測試標籤裡的 ~ 是給人讀的路徑字面，實際路徑走 $sgi/home
if grep -q '<w@example.com>' <<< "$(sgi_ident "$sgi/home" Projects/repo-a)"; then ok "~/Projects → 工作身分"; else bad "~/Projects 解析錯（$(sgi_ident "$sgi/home" Projects/repo-a)）"; fi
# shellcheck disable=SC2088  # 同上
if grep -q '<p@example.com>' <<< "$(sgi_ident "$sgi/home" SideProjects/repo-b)"; then ok "~/SideProjects → 個人身分"; else bad "~/SideProjects 解析錯（$(sgi_ident "$sgi/home" SideProjects/repo-b)）"; fi
# shellcheck disable=SC2088  # 同上
if grep -q '<w@example.com>' <<< "$(sgi_ident "$sgi/home" .dotfiles)"; then ok "~/.dotfiles → 工作身分（它不在任何專案根底下，靠自己那條 includeIf）"; else bad "~/.dotfiles 解析錯（$(sgi_ident "$sgi/home" .dotfiles)）"; fi

# 本節最重要的一格：分界外必須**擋下**，而不是捏造 <user>@<hostname>
sgi_out="$(sgi_ident "$sgi/home" Elsewhere/repo-c)"
if grep -q 'Author identity unknown' <<< "$sgi_out"; then
    ok "分界外 → Author identity unknown（擋下，不捏造）"
else
    bad "分界外未被擋下：$sgi_out"
fi

# --check 契約
sgi_run "$sgi/home" --check >/dev/null 2>&1
assert_rc "--check 收斂後 → exit 0" 0 $?
sgi_out="$(sgi_run "$sgi/home" --check)"
if grep -q 'verdict: OK' <<< "$sgi_out"; then ok "--check 印 verdict: OK"; else bad "--check 未印 verdict（${sgi_out}）"; fi
# --check 必須是唯讀：拿它當驗證手段的人不預期它會改東西
mv "$sgi/home/.gitconfig-personal" "$sgi/home/.gitconfig-personal.hidden"
sgi_run "$sgi/home" --check >/dev/null 2>&1
assert_rc "--check 缺身分檔 → exit 1" 1 $?
if [ -e "$sgi/home/.gitconfig-personal" ]; then bad "--check 竟自行補寫身分檔"; else ok "--check 唯讀（不自行修復）"; fi
mv "$sgi/home/.gitconfig-personal.hidden" "$sgi/home/.gitconfig-personal"

# --check 與 --apply 互斥（避免「我以為只是看看」變成寫入）
sgi_run "$sgi/home" --check --apply >/dev/null 2>&1
assert_rc "--check 與 --apply 併用 → exit 2" 2 $?

# 幂等：重跑不需要再給值（沿用既有身分檔），且結果不變
sgi_run "$sgi/home" --apply >/dev/null 2>&1
assert_rc "--apply 幂等（值可從既有身分檔沿用）" 0 $?
if grep -q '<w@example.com>' <<< "$(sgi_ident "$sgi/home" Projects/repo-a)"; then ok "幂等後身分不變"; else bad "重跑後身分跑掉了"; fi

# ---- 沙盒 2：legacy 值要能當工作 email 的預設（12 台機隊一鍵收斂靠這條） ----
# 那 12 台 ~/.gitconfig 寫死的正好就是工作 email，所以不必逐台重打；但它必須是**繼承**、
# 不是猜——繼承完那個值就從 ~/.gitconfig 移除，避免兩份來源。
sgi_mkhome "$sgi/inherit" legacy
sgi_run "$sgi/inherit" --apply >/dev/null 2>&1
assert_rc "無 flag 但有 legacy 身分 → exit 0（繼承）" 0 $?
if grep -q '<legacy@example.com>' <<< "$(sgi_ident "$sgi/inherit" Projects/repo-a)"; then ok "legacy 值被繼承為工作身分"; else bad "未繼承 legacy 值（$(sgi_ident "$sgi/inherit" Projects/repo-a)）"; fi
if [ -e "$sgi/inherit/.gitconfig-personal" ]; then bad "沒給個人 email 卻寫了 personal 身分檔"; else ok "未提供個人 email → 不寫 personal 身分檔"; fi
if grep -q 'Author identity unknown' <<< "$(sgi_ident "$sgi/inherit" SideProjects/repo-b)"; then ok "缺 personal 身分檔 → 個人分界被擋下（不回退到工作身分）"; else bad "個人分界竟解析出身分"; fi

# ---- 沙盒 3：真的無值可繼承時必須 STOP，不得寫出半套設定 ----
sgi_mkhome "$sgi/bare"
sgi_run "$sgi/bare" --apply >/dev/null 2>&1
assert_rc "非互動且無任何可繼承的值 → exit 1（STOP）" 1 $?
if [ -e "$sgi/bare/.gitconfig-work" ]; then bad "STOP 時仍寫出身分檔"; else ok "STOP 時零 mutation"; fi

# 共用層與腳本的檔名契約：改名只改一邊會讓 include 靜默失效
for sgi_f in .gitconfig-work .gitconfig-personal; do
    if grep -q "$sgi_f" "$ROOT/git/config"; then ok "git/config 引用 ${sgi_f}"; else bad "git/config 未引用 ${sgi_f}（檔名契約已破）"; fi
done
# 共用層**不得**含 email：dotfiles 是公開 bootstrap 的來源
if grep -qE '^[[:space:]]*email[[:space:]]*=' "$ROOT/git/config"; then bad "git/config 含 email（身分不該進 repo）"; else ok "git/config 不含任何 email"; fi


echo "▶ 27. Codex config merge 與 dotsync 聚合終判"
CODEX_CONFIG_HELPER="$ROOT/scripts/ensure-codex-config.py"
if ! rg -q 'preferred_auth_method|preferredAuthMethod' \
    "$ROOT/codex/config.toml" \
    "$ROOT/scripts/ensure-codex-config.py" \
    "$ROOT/setup-mac-env.sh" \
    "$ROOT/setup-linux-env.sh" \
    "$ROOT/scripts/brewup.sh" \
    "$ROOT/scripts/dotfiles-sync.sh"; then
    ok "Codex config 與所有部署入口不再定義 preferred_auth_method"
else
    bad "Codex config 或部署入口仍定義 preferred_auth_method"
fi
ccm="$TMP/codex-config-merge"
mkdir -p "$ccm/dotfiles/codex" "$ccm/home"
cat > "$ccm/dotfiles/codex/config.toml" <<'CCMBASE'
model = "repo"
preferred_auth_method = "apikey"
sandbox_mode = "danger-full-access"

[notice.model_migrations]
"repo-old" = "repo-new"
CCMBASE
cat > "$ccm/home/config.toml" <<'CCMCURRENT'
model = "stale-runtime-copy"
runtime_only = "keep"

[notice.model_migrations]
"repo-old" = "stale-copy"
"runtime-added" = "runtime-new"

[projects."/tmp/example"]
trust_level = "trusted"
CCMCURRENT
cat > "$ccm/home/config.local.toml" <<'CCMLOCAL'
model = "local"
local_only = "wins"

[projects."/tmp/example"]
trust_level = "untrusted"
CCMLOCAL
DOTFILES_DIR="$ccm/dotfiles" CODEX_HOME="$ccm/home" python3 "$CODEX_CONFIG_HELPER" >/dev/null 2>&1; rc=$?
assert_rc "三層 Codex config merge → exit 0" 0 "$rc"
assert_eq "local overlay 最終優先" "local" "$(yq eval '.model' -p toml "$ccm/home/config.toml" 2>/dev/null)"
assert_eq "runtime-only top-level state 保留" "keep" "$(yq eval '.runtime_only' -p toml "$ccm/home/config.toml" 2>/dev/null)"
assert_eq "runtime-only nested state 保留" "runtime-new" "$(yq eval '.notice.model_migrations."runtime-added"' -p toml "$ccm/home/config.toml" 2>/dev/null)"
assert_eq "repo-managed nested value 更新" "repo-new" "$(yq eval '.notice.model_migrations."repo-old"' -p toml "$ccm/home/config.toml" 2>/dev/null)"
assert_eq "local project trust 覆蓋 generated state" "untrusted" "$(yq eval '.projects."/tmp/example".trust_level' -p toml "$ccm/home/config.toml" 2>/dev/null)"
ccm_before="$(cksum < "$ccm/home/config.toml")"
DOTFILES_DIR="$ccm/dotfiles" CODEX_HOME="$ccm/home" python3 "$CODEX_CONFIG_HELPER" >/dev/null 2>&1
assert_eq "Codex config merge 冪等" "$ccm_before" "$(cksum < "$ccm/home/config.toml")"
sed -i.bak '/^preferred_auth_method = /d' "$ccm/dotfiles/codex/config.toml"
rm "$ccm/dotfiles/codex/config.toml.bak"
DOTFILES_DIR="$ccm/dotfiles" CODEX_HOME="$ccm/home" python3 "$CODEX_CONFIG_HELPER" >/dev/null 2>&1
assert_eq "repo base 移除的舊 managed auth key 不會殘留" "null" "$(yq eval '.preferred_auth_method' -p toml "$ccm/home/config.toml" 2>/dev/null)"
printf '%s\n' 'model = "local"' > "$ccm/home/config.local.toml"
DOTFILES_DIR="$ccm/dotfiles" CODEX_HOME="$ccm/home" python3 "$CODEX_CONFIG_HELPER" >/dev/null 2>&1
assert_eq "local override 移除後不會黏成 runtime state" "null" "$(yq eval '.local_only' -p toml "$ccm/home/config.toml" 2>/dev/null)"

ccm_valid="$(cat "$ccm/home/config.toml")"
printf '%s\n' 'not = [valid' > "$ccm/home/config.local.toml"
DOTFILES_DIR="$ccm/dotfiles" CODEX_HOME="$ccm/home" python3 "$CODEX_CONFIG_HELPER" >/dev/null 2>&1; rc=$?
assert_rc "壞 local TOML → exit 1" 1 "$rc"
assert_eq "壞 local TOML 不動既有有效 config" "$ccm_valid" "$(cat "$ccm/home/config.toml")"
printf '%s\n' 'model = "local"' > "$ccm/home/config.local.toml"
YQ_BIN="$ccm/missing-yq" DOTFILES_DIR="$ccm/dotfiles" CODEX_HOME="$ccm/home" python3 "$CODEX_CONFIG_HELPER" >/dev/null 2>&1; rc=$?
assert_rc "merge dependency 缺失 → exit 1" 1 "$rc"
assert_eq "dependency 缺失不動既有 config" "$ccm_valid" "$(cat "$ccm/home/config.toml")"
mkdir "$ccm/home/config.toml.lock"
DOTFILES_DIR="$ccm/dotfiles" CODEX_HOME="$ccm/home" python3 "$CODEX_CONFIG_HELPER" >/dev/null 2>&1; rc=$?
assert_rc "已有 writer lock → exit 1" 1 "$rc"
assert_eq "writer lock 衝突不動既有 config" "$ccm_valid" "$(cat "$ccm/home/config.toml")"
rmdir "$ccm/home/config.toml.lock"

mkdir -p "$ccm/bin"
ccm_real_yq="$(command -v yq)"
cat > "$ccm/bin/yq" <<'CCMYQ'
#!/usr/bin/env bash
if grep -q -- '-p json' <<< "$*"; then
    : > "$CCM_RACE_READY"
    i=0
    while [ ! -e "$CCM_RACE_RELEASE" ] && [ "$i" -lt 500 ]; do
        sleep 0.01
        i=$((i + 1))
    done
fi
exec "$REAL_YQ" "$@"
CCMYQ
chmod +x "$ccm/bin/yq"
CCM_RACE_READY="$ccm/ready" CCM_RACE_RELEASE="$ccm/release" REAL_YQ="$ccm_real_yq" \
    YQ_BIN="$ccm/bin/yq" DOTFILES_DIR="$ccm/dotfiles" CODEX_HOME="$ccm/home" \
    python3 "$CODEX_CONFIG_HELPER" >/dev/null 2>&1 &
ccm_pid=$!
for _ccm_wait in $(seq 1 500); do [ -e "$ccm/ready" ] && break; sleep 0.01; done
printf '%s\n' 'external = "wins"' > "$ccm/home/config.toml"
: > "$ccm/release"
wait "$ccm_pid"; rc=$?
assert_rc "render 期間 config 被其他 writer 改動 → exit 1" 1 "$rc"
assert_eq "race guard 保留外部 writer 內容" "wins" "$(yq eval '.external' -p toml "$ccm/home/config.toml" 2>/dev/null)"

for wiring_file in setup-mac-env.sh setup-linux-env.sh scripts/brewup.sh; do
    if grep -q 'bash .*scripts/ensure-runtime.sh' "$ROOT/$wiring_file"; then ok "$wiring_file 使用共用 runtime entry"; else bad "$wiring_file 未使用共用 runtime entry"; fi
done
assert_eq "dotsync 本機＋遠端都使用共用 runtime entry" 2 "$(grep -c 'bash .*scripts/ensure-runtime.sh' "$ROOT/scripts/dotfiles-sync.sh")"
if ! rg -q '__extract_codex_local_config' "$ROOT/setup-mac-env.sh" "$ROOT/setup-linux-env.sh"; then
    ok "setup 的兩份 inline Codex merge 已移除"
else
    bad "setup 仍留著 inline Codex merge 複本"
fi

ds="$TMP/dotsync-e2e"
mkdir -p "$ds/dotfiles/scripts" "$ds/home/.ssh" "$ds/bin" "$ds/remote/.dotfiles/scripts"
cp "$bup/dotfiles/scripts/ensure-runtime.sh" "$bup/dotfiles/scripts/ensure-runtime-layout.py" "$ds/dotfiles/scripts/"
cp -R "$bup/dotfiles/codex" "$bup/dotfiles/claude" "$ds/dotfiles/"
cp "$ROOT/scripts/ensure-codex-guidance.sh" "$ROOT/scripts/ensure-codex-config.py" "$ds/dotfiles/scripts/"
cp -R "$ds/dotfiles/." "$ds/remote/.dotfiles/"
cp "$bup/bin/ps" "$ds/bin/ps"
# yq dependency failure exercises the real config helper in both local and remote entry.
cat > "$ds/bin/yq" <<'DSYQ'
#!/usr/bin/env bash
[ "${DOTSYNC_CONFIG_FAIL:-0}" = 1 ] && exit 1
exec "$DOTSYNC_REAL_YQ" "$@"
DSYQ
chmod +x "$ds/bin/yq"
export DOTSYNC_REAL_YQ="$bup_real_yq" DOTSYNC_REMOTE_HOME="$ds/remote"
printf 'hostgood 127.0.0.1\nhostbad 127.0.0.2\n' > "$ds/inventory"
cat > "$ds/bin/git" <<'DSGIT'
#!/usr/bin/env bash
if [ "${DOTSYNC_GIT_FAIL:-0}" = 1 ] && [ "${1:-}" = pull ]; then exit 1; fi
exit 0
DSGIT
cat > "$ds/bin/ssh" <<'DSSSH'
#!/usr/bin/env bash
for arg in "$@"; do
    case "$arg" in
      hostbad) printf '%s\n' hostbad >> "$DOTSYNC_SSH_LOG"; exit 255 ;;
      hostgood)
        printf '%s\n' hostgood >> "$DOTSYNC_SSH_LOG"
        for remote_command in "$@"; do :; done
        HOME="$DOTSYNC_REMOTE_HOME" bash -c "$remote_command"
        exit $? ;;
    esac
done
exit 255
DSSSH
chmod +x "$ds/bin/git" "$ds/bin/ssh"
out="$(INVENTORY_FILE="$ds/inventory" DOTFILES_DIR="$ds/dotfiles" HOME="$ds/home" \
    DOTSYNC_SSH_LOG="$ds/ssh.log" PATH="$ds/bin:$PATH" bash "$ROOT/scripts/dotfiles-sync.sh" hostgood hostbad 2>&1)"; rc=$?
assert_rc "任一遠端失敗 → dotsync exit 1" 1 "$rc"
assert_eq "遠端失敗仍跑完所有 requested hosts" 2 "$(wc -l < "$ds/ssh.log" | tr -d ' ')"
if grep -q 'remote_ok=1 remote_failed=1' <<< "$out"; then ok "dotsync 輸出遠端聚合總計"; else bad "dotsync 缺遠端聚合總計"; fi
: > "$ds/ssh.log"
out="$(DOTSYNC_GIT_FAIL=1 INVENTORY_FILE="$ds/inventory" DOTFILES_DIR="$ds/dotfiles" HOME="$ds/home" \
    DOTSYNC_SSH_LOG="$ds/ssh.log" PATH="$ds/bin:$PATH" bash "$ROOT/scripts/dotfiles-sync.sh" hostgood 2>&1)"; rc=$?
assert_rc "本機 pull 失敗 → dotsync exit 1" 1 "$rc"
assert_eq "本機失敗後仍嘗試遠端" 1 "$(wc -l < "$ds/ssh.log" | tr -d ' ')"
if grep -q 'local=failed' <<< "$out"; then ok "dotsync 總計揭露本機失敗"; else bad "dotsync 總計漏掉本機失敗"; fi
: > "$ds/ssh.log"
out="$(INVENTORY_FILE="$ds/inventory" DOTFILES_DIR="$ds/dotfiles" HOME="$ds/home" \
    DOTSYNC_SSH_LOG="$ds/ssh.log" PATH="$ds/bin:$PATH" bash "$ROOT/scripts/dotfiles-sync.sh" hostgood 2>&1)"; rc=$?
assert_rc "本機與所有遠端成功 → dotsync exit 0" 0 "$rc"
if grep -q 'local=ok remote_ok=1 remote_failed=0' <<< "$out"; then ok "dotsync 全綠總計正確"; else bad "dotsync 全綠總計錯誤"; fi

out="$(DOTSYNC_CONFIG_FAIL=1 INVENTORY_FILE="$ds/inventory" DOTFILES_DIR="$ds/dotfiles" HOME="$ds/home" \
    DOTSYNC_SSH_LOG="$ds/ssh.log" PATH="$ds/bin:$PATH" bash "$ROOT/scripts/dotfiles-sync.sh" hostgood 2>&1)"; rc=$?
assert_rc "真實 entry 的 config 失敗 → dotsync exit 1" 1 "$rc"
if grep -q 'local=failed remote_ok=0 remote_failed=1' <<< "$out"; then ok "local/remote entry 失敗都納入 dotsync 終判"; else bad "dotsync 漏掉真實 entry 失敗"; fi
if [ -L "$ds/home/.claude/skills/demo" ] && [ -L "$ds/remote/.agents/skills/demo" ]; then ok "dotsync 真正執行 local/remote runtime layout"; else bad "dotsync runtime entry 接線失效"; fi
