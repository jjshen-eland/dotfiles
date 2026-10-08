#!/usr/bin/env bash
# The canonical 18d oracle, sourced by run.sh or run independently.
# Usage: bash tests/brewup-tests.sh
# BREWUP_TEST_SCRIPT may point at a disposable mutation-control script.
set -uo pipefail

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
    cd "$ROOT" || exit 1
    TMP="$(mktemp -d)" || exit 1
    [ -n "$TMP" ] && [ -d "$TMP" ] || exit 1
    trap 'rm -rf "$TMP"' EXIT
    PASS=0
    FAIL=0
    # shellcheck source=lib/assertions.sh
    source "$ROOT/tests/lib/assertions.sh"
fi

echo "▶ 18d. brewup.sh helper 部署與失敗告知（全隔離）"
# brewup 除了 helper 還會跑 git / brew / claude / jq 與 cp known_hosts。fixture 必須同時
# 隔離 DOTFILES_DIR、HOME 與 PATH——否則這節測試本身會去動真的 repo、真的 Homebrew 與真的 $HOME。
BUP="${BREWUP_TEST_SCRIPT:-$ROOT/scripts/brewup.sh}"
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

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    printf 'BREWUP_RESULT pass=%s fail=%s\n' "$PASS" "$FAIL"
    [ "$FAIL" -eq 0 ]
fi
