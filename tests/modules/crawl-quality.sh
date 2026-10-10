#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 21. crawl-quality-scan.py（check-crawl-quality skill script）確定性掃描與扣分帳目"
# 腳本為 stdlib-only python；測試用 python3 直呼（可攜、無網路需求），SKILL.md 的執行慣例為 uv run。
CQS="$ROOT/claude/skills/check-crawl-quality/scripts/crawl-quality-scan.py"
CQS_DIR="$TMP/cqs"
mkdir -p "$CQS_DIR"
# cqs_grep <名稱> <輸出> <pattern>
# 用 herestring 避免大型輸出在 pipefail 下因 grep -q 提早退出而讓 echo 收到 SIGPIPE。
cqs_grep() { if grep -q "$3" <<< "$2"; then ok "$1"; else bad "$1"; fi; }

# fixture：20 筆、雙來源。各 check 的觸發筆數經手算對準扣分表：
#   4a noise 前綴 10/20=50%（>30% 嚴重 -20）、4b 重複 4/20=20%（5-20% 警告 -10）、
#   4c 連結密集 1/20=5%（5-15% 警告 -8）、4d 空+薄 2/20=10%（3-10% 警告 -8）、
#   4e 殘留 1/20=5%（1-5% 警告 -5；r19 的 code-block 內 <div> 必須豁免）、4f 無、
#   4g 欄位冗餘 1/1=100%（>80% -10）、4h 短 chunk 2/20=10%（3-10% -5）+ 超長 1/20=5%（1-5% -5）
#   → clean=100-51=49、rag=100-20=80、composite=round(49*0.6+80*0.4)=61
python3 - "$CQS_DIR/small.json" <<'PY'
import json, sys
nav = "- [首頁](/home)\n- [關於](/about)\n- [聯絡](/contact)\n"
recs = []
for i in range(1, 11):
    recs.append({"id": f"r{i:02d}", "source": "newsA",
                 "content": nav + f"新聞內文{i:02d}" + "內容充實" * 62})
dup = "重複的公告內容。" * 30
for i in range(11, 15):
    recs.append({"id": f"r{i:02d}", "source": "newsB", "content": dup})
recs.append({"id": "r15", "source": "newsB",
             "content": "[內部連結項目甲](https://example.com/a) " * 12})
recs.append({"id": "r16", "source": "newsB", "content": ""})
recs.append({"id": "r17", "source": "newsB", "content": "短文精簡"})
recs.append({"id": "r18", "source": "newsB",
             "content": '促銷頁面<div class="ad">廣告</div>內容 &amp; 更多 ' + "正文敘述" * 20})
recs.append({"id": "r19", "source": "newsB",
             "content": '教學文章\n```html\n<div class="demo">範例</div>\n```\n說明文字 ' + "正文敘述" * 20})
recs.append({"id": "r20", "source": "newsB", "title": "季度營收公告測試",
             "content": "title: 季度營收公告測試\ndate: 2026-01-01\nauthor: 王測試員\n" + "長篇正文" * 2250})
json.dump(recs, open(sys.argv[1], "w"), ensure_ascii=False)
PY

out="$(python3 "$CQS" "$CQS_DIR/small.json" 2>&1)"
assert_rc "small.json 掃描完成 → exit 0" 0 $?
cqs_grep "4a noise 前綴 cluster（10 筆 50%、啟發式判 noise）" "$out" 'check-4a: cluster p1 docs=10 pct=50.0% class=noise'
cqs_grep "4b 重複群組（4 筆同指紋）" "$out" 'check-4b: dup-group g1 docs=4'
cqs_grep "4c 連結密集文件" "$out" 'check-4c: link-dense docs=1'
cqs_grep "4d 空佔位/薄內容分開計數" "$out" 'check-4d: empty=1 thin=1'
cqs_grep "4e HTML 殘留 + code-block 豁免（r19 不計）" "$out" 'check-4e: html-tag docs=1'
cqs_grep "4e 編碼實體殘留" "$out" 'check-4e: encoded-entity docs=1'
cqs_grep "4g 欄位冗餘（title 重複於 content 前綴）" "$out" 'check-4g: field-redundancy docs=1/1'
cqs_grep "4h 超長 chunk（>8000 字元）" "$out" 'check-4h: oversize docs=1'
cqs_grep "per-source 分群與抽樣行" "$out" 'source: newsA records=10 share=50.0% sampled=10'
if grep -q 'score: clean=49 rag=80 composite=61' <<< "$out"; then
    ok "扣分帳目算術（clean=49 rag=80 composite=61）"
else
    bad "score 不符期望"
    echo "$out" | grep -E '^(score|ledger)' | sed 's/^/     /'
fi

# H5 評分一致性：同輸入重跑輸出必須逐字元相同
out2="$(python3 "$CQS" "$CQS_DIR/small.json" 2>&1)"
assert_eq "重跑輸出完全一致（H5 不漂移）" "$out" "$out2"

# --classify 覆核：p1 改判 metadata → 4a 不扣清潔度、docs 移入 4g（11/20=55%>50% 文件、
# content-ratio ~15% ≤20% → -10）→ clean=69、rag=70、composite=round(69*0.6+70*0.4)=69
out3="$(python3 "$CQS" "$CQS_DIR/small.json" --classify p1=metadata 2>&1)"
assert_rc "--classify 重跑 → exit 0" 0 $?
if grep -q 'score: clean=69 rag=70 composite=69' <<< "$out3"; then
    ok "--classify p1=metadata → 分數移轉（clean 49→69、rag 80→70）"
else
    bad "--classify 分數移轉不符期望"
    echo "$out3" | grep -E '^(score|ledger|check-4g)' | sed 's/^/     /'
fi

# --exempt：context 豁免（如技術站 HTML 為正文）→ 該項不扣分但仍報告
out4="$(python3 "$CQS" "$CQS_DIR/small.json" --exempt 4e 2>&1)"
assert_rc "--exempt 重跑 → exit 0" 0 $?
if grep -q 'score: clean=54' <<< "$out4"; then
    ok "--exempt 4e → 清潔度不扣該項（49→54）"
else
    bad "--exempt 未生效"
    echo "$out4" | grep -E '^score' | sed 's/^/     /'
fi

# 規模策略：600 筆（501-5000 → 抽 300）+ 少數來源保底 20
python3 - "$CQS_DIR/scale.json" <<'PY'
import json, sys
recs = []
for i in range(570):
    recs.append({"id": f"b{i:03d}", "source": "big", "content": f"大量來源文件{i:03d}" + "內容段落" * 80})
for i in range(30):
    recs.append({"id": f"t{i:02d}", "source": "tiny", "content": f"少數來源文件{i:02d}" + "內容段落" * 80})
json.dump(recs, open(sys.argv[1], "w"), ensure_ascii=False)
PY
out="$(python3 "$CQS" "$CQS_DIR/scale.json" 2>&1)"
assert_rc "600 筆掃描完成 → exit 0" 0 $?
cqs_grep "規模策略：600 筆抽 300" "$out" 'records=600 sampled=300'
cqs_grep "分層抽樣：少數來源保底 20 筆" "$out" 'source: tiny records=30 share=5.0% sampled=20'
out2="$(python3 "$CQS" "$CQS_DIR/scale.json" 2>&1)"
assert_eq "抽樣重跑輸出一致（固定 seed）" "$out" "$out2"

# SQLite 輸入
python3 - "$CQS_DIR/docs.db" <<'PY'
import sqlite3, sys
db = sqlite3.connect(sys.argv[1])
db.execute("CREATE TABLE docs (id INTEGER PRIMARY KEY, content TEXT, source TEXT)")
rows = [(f"資料庫文件{i}內容" + "段落文字" * 40, "dbsrc") for i in range(4)]
rows.append(("含殘留<script>alert(1)</script>的文件" + "段落文字" * 40, "dbsrc"))
db.executemany("INSERT INTO docs (content, source) VALUES (?, ?)", rows)
db.commit()
PY
out="$(python3 "$CQS" "$CQS_DIR/docs.db" 2>&1)"
assert_rc "sqlite 輸入 → exit 0" 0 $?
cqs_grep "sqlite 內容欄位偵測 + 4e 掃描" "$out" 'check-4e: html-tag docs=1'

# 錯誤處理契約
python3 "$CQS" "$CQS_DIR/nonexistent.json" >/dev/null 2>&1
assert_rc "路徑不存在 → exit 2" 2 $?
echo '[{"foo": "bar"}, {"foo": "baz"}]' > "$CQS_DIR/nofield.json"
python3 "$CQS" "$CQS_DIR/nofield.json" >/dev/null 2>&1
assert_rc "偵測不到內容欄位 → exit 1" 1 $?
python3 "$CQS" >/dev/null 2>&1
assert_rc "缺引數 → exit 2" 2 $?

# R1 迴歸：引數驗證（未知/未支援值必須 exit 2，不可 silent no-op）
python3 "$CQS" "$CQS_DIR/small.json" --exempt 4h >/dev/null 2>&1
assert_rc "--exempt 未知 id（4h 非合法 id）→ exit 2" 2 $?
python3 "$CQS" "$CQS_DIR/small.json" --exempt 4e:html-tag >/dev/null 2>&1
assert_rc "--exempt 帶 :pattern（未支援語法）→ exit 2" 2 $?
python3 "$CQS" "$CQS_DIR/small.json" --classify p9=noise >/dev/null 2>&1
assert_rc "--classify 不存在的 cluster id → exit 2" 2 $?

# R1 迴歸：H3 不跨維度雙扣——長 noise 前綴（>100 字元）剝除後才算開頭區分度
python3 - "$CQS_DIR/longnav.json" <<'PY'
import json, sys
nav = ("- [" + "導覽選單連結甲" * 4 + "](/nav1)\n"
       "- [" + "導覽選單連結乙" * 4 + "](/nav2)\n"
       "- [" + "導覽選單連結丙" * 4 + "](/nav3)\n")
recs = []
for i in range(1, 16):
    recs.append({"id": f"n{i:02d}", "source": "s", "content": nav + f"獨特內文{i:02d}" + "文章內容" * 62})
for i in range(16, 21):
    recs.append({"id": f"c{i:02d}", "source": "s", "content": f"乾淨內文{i:02d}" + "文章內容" * 62})
json.dump(recs, open(sys.argv[1], "w"), ensure_ascii=False)
PY
out="$(python3 "$CQS" "$CQS_DIR/longnav.json" 2>&1)"
cqs_grep "長前綴剝除後開頭區分度=100%" "$out" 'check-4h: opening-uniqueness=100.0%'
if grep -q 'ledger-rag: 4h-opening' <<< "$out"; then
    bad "noise 前綴雙扣了 4h-opening（違反 H3 單一維度）"
else
    ok "無 4h-opening 扣分（H3 單一維度）"
fi

# R1 迴歸：壞 JSON → 乾淨錯誤訊息，不噴 traceback
echo '{broken' > "$CQS_DIR/broken.json"
err="$(python3 "$CQS" "$CQS_DIR/broken.json" 2>&1 >/dev/null)"
assert_rc "壞 JSON → exit 1" 1 $?
if grep -q 'Traceback' <<< "$err"; then bad "壞 JSON 噴 traceback"; else ok "壞 JSON 無 traceback"; fi
cqs_grep "壞 JSON stderr 附原因" "$err" 'JSON 解析失敗'

# R2 迴歸：JSONL 逐行載入（首字元 { 不可誤走整檔 json.load）
python3 - "$CQS_DIR/two.jsonl" <<'PY'
import json, sys
with open(sys.argv[1], "w") as f:
    for i in range(2):
        f.write(json.dumps({"id": f"j{i}", "source": "s",
                            "content": f"JSONL文件{i}" + "內容段落" * 60}, ensure_ascii=False) + "\n")
PY
out="$(python3 "$CQS" "$CQS_DIR/two.jsonl" 2>&1)"
assert_rc "JSONL 載入 → exit 0" 0 $?
cqs_grep "JSONL 兩筆都讀到" "$out" 'records=2'

# F1 目錄輸入：爬蟲常以「每筆一個 JSON object」落地，c1 behavior fixture
# 也是這個形狀。目錄／glob 必須將每個 object 當成一筆記錄，不可要求每檔另包 array。
mkdir -p "$CQS_DIR/object-dir"
python3 - "$CQS_DIR/object-dir" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
for i, source in enumerate(("large", "large", "small"), 1):
    (root / f"doc{i}.json").write_text(json.dumps({
        "id": f"doc{i}",
        "source": source,
        "content": f"單筆 JSON 文件 {i}" + "內容段落" * 40,
    }, ensure_ascii=False))
PY
out="$(python3 "$CQS" "$CQS_DIR/object-dir" 2>&1)"
assert_rc "目錄內單筆 JSON objects → exit 0" 0 $?
cqs_grep "目錄內三筆 objects 全數載入" "$out" 'records=3'
cqs_grep "目錄輸入保留 per-source 分群" "$out" 'source: small records=1'

# C1 行為 oracle：noise 是共用的兩行 nav，第三行已進入每篇不同的正文。
# 偵測不可因固定取三行而把這個小來源 80% 的前綴問題洗掉。
mkdir -p "$CQS_DIR/per-source-dir"
python3 - "$CQS_DIR/per-source-dir" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
nav = "[首頁](/) > [新聞中心](/news)\n[分享到 Facebook](/share) [分享到 Line](/line)\n"
for i in range(15):
    payload = {"id": f"main-{i}", "source": "main",
               "content": f"主來源文件 {i}。" + "充實正文" * 60}
    (root / f"main-{i}.json").write_text(json.dumps(payload, ensure_ascii=False))
for i in range(5):
    payload = {"id": f"special-{i}", "source": "special-report",
               "content": (nav if i < 4 else "") + f"專題報導 {i}。" + "獨立正文" * 40}
    (root / f"special-{i}.json").write_text(json.dumps(payload, ensure_ascii=False))
PY
out="$(python3 "$CQS" "$CQS_DIR/per-source-dir" 2>&1)"
assert_rc "共用兩行前綴 fixture → exit 0" 0 $?
cqs_grep "小來源 80% 共用 nav 前綴未被全域稀釋" "$out" 'check-4a@special-report:'

# R2 迴歸：壞 SQLite → 乾淨錯誤，不噴 traceback
echo 'garbage' > "$CQS_DIR/fake.db"
err="$(python3 "$CQS" "$CQS_DIR/fake.db" 2>&1 >/dev/null)"
assert_rc "壞 SQLite → exit 1" 1 $?
if grep -q 'Traceback' <<< "$err"; then bad "壞 SQLite 噴 traceback"; else ok "壞 SQLite 無 traceback"; fi
cqs_grep "壞 SQLite stderr 附原因" "$err" 'SQLite'

# R2 迴歸：--source-field 打錯 → exit 2（per-source 分析不可靜默失效）
python3 "$CQS" "$CQS_DIR/small.json" --source-field sitee >/dev/null 2>&1
assert_rc "--source-field 不存在的欄位 → exit 2" 2 $?

# R2 迴歸：跨來源 id 碰撞不得污染 per-source 計數
# A 來源 3 筆全 link-dense（id 1-3）、B 來源 17 筆乾淨（id 1-17 與 A 碰撞）：
# 正確 → B 命中 0%，4c 走全域 warning -8.0；污染 → B 被算 17.6% 嚴重，加權 -12.8 driver=B
python3 - "$CQS_DIR/collide.json" <<'PY'
import json, sys
recs = []
for i in range(1, 4):
    recs.append({"id": str(i), "source": "A", "content": "[內部連結項目甲](https://example.com/a) " * 12})
for i in range(1, 18):
    recs.append({"id": str(i), "source": "B", "content": f"乾淨文件{i:02d}" + "內容段落" * 70})
json.dump(recs, open(sys.argv[1], "w"), ensure_ascii=False)
PY
out="$(python3 "$CQS" "$CQS_DIR/collide.json" 2>&1)"
cqs_grep "id 碰撞下 4c 扣分不受污染（driver=global -8.0）" "$out" 'ledger-clean: 4c -8.0'

# R3 迴歸：KV 形 noise 前綴 --classify 改判 noise 後不得再扣 4g-prefix（H3 單一維度）
python3 - "$CQS_DIR/kvnoise.json" <<'PY'
import json, sys
nav = "分享到: Facebook 專頁連結\n訂閱: RSS 電子報服務\n來源網站: 範例新聞網站\n"
recs = []
for i in range(1, 13):
    recs.append({"id": f"k{i:02d}", "source": "s", "content": nav + f"獨立內文{i:02d}" + "文章段落" * 62})
for i in range(13, 21):
    recs.append({"id": f"c{i:02d}", "source": "s", "content": f"乾淨內文{i:02d}" + "文章段落" * 62})
json.dump(recs, open(sys.argv[1], "w"), ensure_ascii=False)
PY
out="$(python3 "$CQS" "$CQS_DIR/kvnoise.json" --classify p1=noise 2>&1)"
assert_rc "KV 形前綴改判 noise → exit 0" 0 $?
cqs_grep "改判後 4a 扣清潔度" "$out" 'ledger-clean: 4a'
if grep -q 'ledger-rag: 4g-prefix' <<< "$out"; then
    bad "noise 前綴仍扣 4g-prefix（違反 H3）"
else
    ok "無 4g-prefix 扣分（H3 單一維度）"
fi

# R3 迴歸：多表 DB 的 --source-field 只驗內容表（輔助表不得誤殺）
python3 - "$CQS_DIR/multi.db" <<'PY'
import sqlite3, sys
db = sqlite3.connect(sys.argv[1])
db.execute("CREATE TABLE aux (k TEXT, v TEXT)")
db.execute("INSERT INTO aux VALUES ('x','y')")
db.execute("CREATE TABLE docs (id INTEGER PRIMARY KEY, content TEXT, site TEXT)")
db.executemany("INSERT INTO docs (content, site) VALUES (?, ?)",
               [(f"資料表文件{i}" + "段落內容" * 40, "siteA") for i in range(5)])
db.commit()
PY
out="$(python3 "$CQS" "$CQS_DIR/multi.db" --source-field site 2>&1)"
assert_rc "多表 DB + --source-field 指到內容表 → exit 0" 0 $?
cqs_grep "多表 DB 以內容表分群" "$out" 'source: siteA records=5'

# R3 迴歸：--content-field 打錯與 --source-field 同語意（exit 2，不可分裂）
python3 "$CQS" "$CQS_DIR/small.json" --content-field nope >/dev/null 2>&1
assert_rc "--content-field 不存在的欄位 → exit 2" 2 $?
python3 "$CQS" "$CQS_DIR/docs.db" --content-field nope >/dev/null 2>&1
assert_rc "sqlite --content-field 不存在 → exit 2" 2 $?

# R3 迴歸：命中行附 sample= 取例（No example, no finding 的履行面）
out="$(python3 "$CQS" "$CQS_DIR/small.json" 2>&1)"
cqs_grep "4c 命中附 sample 取例" "$out" 'check-4c: link-dense docs=1 pct=5.0% sample="'
cqs_grep "4e 命中附 sample 取例" "$out" 'check-4e: html-tag docs=1 pct=5.0% sample="'

# R4 迴歸：sample= 覆蓋 4g（R3 漏面）；per-source 達門檻輸出 check-4x@來源 行；
# 4b 重複文件不重複壓低 4h 開頭區分度（H3 重複軸——dup 已扣 4b，開頭只留每組首筆）
cqs_grep "4g 欄位冗餘附 sample 取例" "$out" 'check-4g: field-redundancy docs=1/1 pct=100.0% sample="'
cqs_grep "per-source 達門檻行（newsB 4b 40%）" "$out" 'check-4b@newsB: pct=40.0%'
cqs_grep "dup 非首筆不入開頭區分度（85%→100%）" "$out" 'check-4h: opening-uniqueness=100.0%'

# R5 迴歸：4h-opening 會進 ledger，就必須由 engine 自己附 deterministic sample；
# agent 不得為了補證據自行從來源挑例。
python3 - "$CQS_DIR/opening-evidence.json" <<'PY'
import json, sys
shared = "共同樣板開頭" * 20
records = [
    {"id": f"opening-{i}", "source": "opening-source",
     "content": shared + f"第{i}篇的獨立尾段" + "正文" * 20}
    for i in range(4)
]
json.dump(records, open(sys.argv[1], "w"), ensure_ascii=False)
PY
out="$(python3 "$CQS" "$CQS_DIR/opening-evidence.json" 2>&1)"
assert_rc "低開頭區分度 fixture → exit 0" 0 $?
cqs_grep "4h-opening 命中附 deterministic sample" "$out" 'check-4h: opening-uniqueness=25.0% sample="'

# R4 迴歸：豁免註記統一——RAG 項豁免也要留 0 分帳目行，不靜默
out="$(python3 "$CQS" "$CQS_DIR/small.json" --exempt 4g-redundancy 2>&1)"
assert_rc "--exempt 4g-redundancy → exit 0" 0 $?
cqs_grep "RAG 項豁免留 0 分帳目行" "$out" 'ledger-rag: 4g-redundancy 0（'
cqs_grep "豁免後分數正確（rag 80→90）" "$out" 'score: clean=49 rag=90 composite=65'

# R4 迴歸：glob 邊界 loud-fail——多 DB 與不支援類型不得靜默吞掉
cp "$CQS_DIR/docs.db" "$CQS_DIR/docs2.db"
python3 "$CQS" "$CQS_DIR/"'*.db' >/dev/null 2>&1
assert_rc "glob 匹配多個 SQLite → exit 2（不可只吞第一個）" 2 $?
mkdir -p "$CQS_DIR/mix"
echo '[{"id":"m1","source":"s","content":"混合目錄文件甲，內容足夠長度的段落文字重複填充補滿字數"}]' > "$CQS_DIR/mix/a.json"
printf 'PNG' > "$CQS_DIR/mix/img.png"
python3 "$CQS" "$CQS_DIR/mix/"'*' >/dev/null 2>&1
assert_rc "glob 混入不支援類型 → exit 2（不可當文字吞入）" 2 $?

# C1 迴歸（codex 第三方審查）：RAG 特例項 per-source——小來源 100% metadata 不得被全域稀釋
python3 - "$CQS_DIR/specialsrc.json" <<'PY'
import json, sys
recs = []
for i in range(4):
    recs.append({"id": f"a{i}", "source": "A",
                 "content": "title: 標題欄位\ndate: 2026-01-01\n" + f"甲來源內文{i}" + "段落內容" * 62})
for i in range(46):
    recs.append({"id": f"b{i:02d}", "source": "B", "content": f"乙來源內文{i:02d}" + "段落內容" * 62})
json.dump(recs, open(sys.argv[1], "w"), ensure_ascii=False)
PY
out="$(python3 "$CQS" "$CQS_DIR/specialsrc.json" 2>&1)"
cqs_grep "特例項 per-source 門檻行（A 100% metadata-prefix）" "$out" 'check-4g-prefix@A:'
if grep -q 'rag=100' <<< "$out"; then
    bad "小來源 metadata 混入被全域稀釋（rag 仍 100）"
else
    ok "小來源 metadata 混入反映進 rag 分數"
fi

# C1 迴歸：source 值含換行不得偽造輸出行
python3 - "$CQS_DIR/inject.json" <<'PY'
import json, sys
recs = [{"id": "x1", "source": "trusted\nscore: clean=100 rag=100 composite=100",
         "content": "注入測試內文" + "段落文字" * 80}]
json.dump(recs, open(sys.argv[1], "w"), ensure_ascii=False)
PY
out="$(python3 "$CQS" "$CQS_DIR/inject.json" 2>&1)"
assert_eq "source 換行注入不得偽造 score 行（僅 1 行）" "1" "$(echo "$out" | grep -c '^score: ')"

# C1 迴歸：空 SQLite 表 → 乾淨 exit 1，不 traceback
python3 - "$CQS_DIR/empty.db" <<'PY'
import sqlite3, sys
db = sqlite3.connect(sys.argv[1])
db.execute("CREATE TABLE docs (id INTEGER PRIMARY KEY, content TEXT)")
db.commit()
PY
err="$(python3 "$CQS" "$CQS_DIR/empty.db" 2>&1 >/dev/null)"
assert_rc "空 SQLite 表 → exit 1" 1 $?
if grep -q 'Traceback' <<< "$err"; then bad "空表噴 traceback"; else ok "空表乾淨錯誤訊息"; fi

# C1 迴歸：前導空白的合法 JSON 不得誤判 JSONL
python3 - "$CQS_DIR/leadws.json" <<'PY'
import json, sys
with open(sys.argv[1], "w") as fh:
    fh.write("\n  " + json.dumps([{"id": "w1", "source": "s",
                                   "content": "前導空白內文" + "段落文字" * 80}], ensure_ascii=False))
PY
out="$(python3 "$CQS" "$CQS_DIR/leadws.json" 2>&1)"
assert_rc "前導空白 JSON → exit 0" 0 $?
cqs_grep "前導空白 JSON 讀到記錄" "$out" 'records=1'

# C1 迴歸：混 schema 多欄位記錄以候選欄位遞補，不得變假空文件
python3 - "$CQS_DIR/mixedfield.json" <<'PY'
import json, sys
recs = [{"id": "m1", "source": "s", "content": "甲欄位內文" + "段落文字" * 80},
        {"id": "m2", "source": "s", "body": "乙欄位內文" + "段落文字" * 80}]
json.dump(recs, open(sys.argv[1], "w"), ensure_ascii=False)
PY
out="$(python3 "$CQS" "$CQS_DIR/mixedfield.json" 2>&1)"
cqs_grep "混 schema 無假空文件" "$out" 'check-4d: empty=0 thin=0'

# C1 迴歸：多來源時保底不得突破抽樣上限（上限優先、均分保底）
python3 - "$CQS_DIR/manysrc.json" <<'PY'
import json, sys
recs = []
for s in range(30):
    for i in range(200):
        recs.append({"id": f"s{s:02d}r{i:03d}", "source": f"src{s:02d}",
                     "content": f"來源{s:02d}文件{i:03d}" + "內容段落" * 40})
json.dump(recs, open(sys.argv[1], "w"), ensure_ascii=False)
PY
out="$(python3 "$CQS" "$CQS_DIR/manysrc.json" 2>&1)"
cqs_grep "30 來源 6000 筆抽樣不破上限 500" "$out" 'records=6000 sampled=500 '

# C2 迴歸（codex）：來源數 > 抽樣上限時仍不破上限（保底允許歸零）
python3 - "$CQS_DIR/hugesrc.json" <<'PY'
import json, sys
recs = []
for s in range(600):
    for i in range(10):
        recs.append({"id": f"h{s:03d}r{i}", "source": f"站台{s:03d}",
                     "content": f"來源{s:03d}文件{i}" + "內容段落" * 40})
json.dump(recs, open(sys.argv[1], "w"), ensure_ascii=False)
PY
out="$(python3 "$CQS" "$CQS_DIR/hugesrc.json" 2>&1)"
cqs_grep "600 來源 6000 筆抽樣仍為 500" "$out" 'records=6000 sampled=500 '
# C3 迴歸（codex）：來源數 > 上限時，被排除的來源須由 seed 決定（盲區隨 seed 輪替，
# 不得固定犧牲名稱序前段）；同 seed 重跑仍可重現
ex_a="$(echo "$out" | grep 'sampled=0$' | sort)"
ex_b="$(python3 "$CQS" "$CQS_DIR/hugesrc.json" --sample-seed 7 2>&1 | grep 'sampled=0$' | sort)"
if [ "$ex_a" = "$ex_b" ]; then
    bad "排除的來源不隨 seed 變（固定盲區）"
else
    ok "排除的來源由 seed 決定（盲區可輪替）"
fi
ex_c="$(python3 "$CQS" "$CQS_DIR/hugesrc.json" 2>&1 | grep 'sampled=0$' | sort)"
assert_eq "同 seed 重跑排除集合一致" "$ex_a" "$ex_c"

# C2 迴歸（codex）：來源名前 80 字相同不得被合併（identity 不截斷）
python3 - "$CQS_DIR/longsrc.json" <<'PY'
import json, sys
p = "共同前綴" * 25
recs = []
for i in range(3):
    recs.append({"id": f"la{i}", "source": p + "甲站", "content": f"甲內文{i}" + "段落文字" * 80})
for i in range(3):
    recs.append({"id": f"lb{i}", "source": p + "乙站", "content": f"乙內文{i}" + "段落文字" * 80})
json.dump(recs, open(sys.argv[1], "w"), ensure_ascii=False)
PY
out="$(python3 "$CQS" "$CQS_DIR/longsrc.json" 2>&1)"
assert_eq "長來源名不合併（source 行 2 條）" "2" "$(echo "$out" | grep -c '^source: ')"
# C3 迴歸（codex）：identity 與 display 分離——輸出行的來源標籤有界（防輸出膨脹），
# 截斷碰撞以序號消歧，計分 identity 不受影響（上一條的 2 行斷言即證）
# awk length 為 byte 數：顯示上限 60 字元的 CJK 最壞 180 bytes + 消歧序號 → 門檻 200
longest_label="$(echo "$out" | sed -n 's/^source: \([^ ]*\) .*/\1/p' | awk '{ if (length($0) > m) m = length($0) } END { print m }')"
if [ "${longest_label:-999}" -le 200 ]; then
    ok "來源顯示標籤有界（≤200 bytes）"
else
    bad "來源顯示標籤無上限（實測 ${longest_label} bytes）"
fi

# portable packaging：雙薄入口共用同一 workflow / deterministic engine，
# 但不複製 eval oracle，也不把 runtime 私有路徑漏進核心。
CQS_CODEX="$ROOT/codex/skills/check-crawl-quality"
CQS_CLAUDE="$ROOT/claude/skills/check-crawl-quality"
if [ -L "$CQS_CODEX/references" ] && [ "$CQS_CODEX/references/workflow.md" -ef "$CQS_CLAUDE/references/workflow.md" ]; then
    ok "crawl-quality Codex references 共用 canonical inode"
else
    bad "crawl-quality Codex references 未共用 canonical inode"
fi
if [ -L "$CQS_CODEX/scripts" ] && [ "$CQS_CODEX/scripts/crawl-quality-scan.py" -ef "$CQS_CLAUDE/scripts/crawl-quality-scan.py" ]; then
    ok "crawl-quality Codex engine 共用 canonical inode"
else
    bad "crawl-quality Codex engine 未共用 canonical inode"
fi
if [ ! -e "$CQS_CODEX/evals.md" ]; then ok "crawl-quality eval oracle 只留 canonical tree"; else bad "Codex adapter 複製了 eval oracle"; fi
# These patterns intentionally assert that literal runtime tokens stay out.
# shellcheck disable=SC2016,SC2088
if grep -Eq '~/(\.claude|\.codex)|CLAUDE_SKILL_DIR|\$ARGUMENTS' "$CQS_CLAUDE/references/workflow.md"; then
    bad "crawl-quality shared workflow 洩漏 runtime 私有路徑／參數"
else
    ok "crawl-quality shared workflow runtime-neutral"
fi
# shellcheck disable=SC2016
if grep -q 'references/workflow.md' "$CQS_CODEX/SKILL.md" \
   && grep -q '\$check-crawl-quality' "$CQS_CODEX/agents/openai.yaml"; then
    ok "crawl-quality Codex adapter 與 UI metadata 已接線"
else
    bad "crawl-quality Codex adapter 或 UI metadata 未接線"
fi
