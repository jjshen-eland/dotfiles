<!--
STATUS.md — 專案 dossier(單一事實來源:repo 內、隨 git 跨主機、隨專案移交)
維護時機:開工寫 spec;ship 時同步;移交前補齊完整度。維護者可能另有工具輔助,
        但**規範本身在此、不在工具**——沒有那些工具也照樣維護得下去。
-->

# STATUS.md

個人 dotfiles——內網主機(清單見 `scripts/inventory.conf`,現 14 台)開發環境與 Claude Code 工作流(skills/hooks/templates)的單一來源(更新日期:2026-09-02)

---

## 進行中

### 容器網路殘留的介面直連路由偵測

- **Writer**: `claude:detect-missing-interface-routes`
- **Workspace**: `branch=feat/detect-missing-interface-routes`
- **Write Scope**: `STATUS.md`, `scripts/check-network-isolation-collisions.py`, `tests/run.sh`, `docs/archive/milestones-2026-09.md`
- **Dossier Steward**: `claude:detect-missing-interface-routes`
- **Success Criteria**: 同一支偵測涵蓋容器網路撞網的第二種殘留——實體介面自己的直連網段路由被 bridge 接走且拆除時不還原；判準要求網段路由存在**且 Netif 綁在該介面本身**，因此 bridge 接管也判 STOP 並點名接管者；未 UP 的 NIC、loopback、point-to-point 不誤報；fixture mode 要求四項證據齊全、介面 flags 不可解析時 fail closed；以 2026-09-02 故障當下的真實路由快照回放能精確指出缺失且零誤報；完整測試全綠。
- **進度**: 實作、測試與實機/回放驗證完成（`./tests/run.sh` 1277 PASS／0 FAIL；乾淨 clone 重跑同樣全綠）。本 active contract 為 `/project` recovery 時補建。
- **下一步**: 寫入 `M-20260902-missing-interface-route-detection` milestone、移除本 active item，依 `--merge` 走完 PR 與 merge。
- **關聯**: `M-20260902-network-isolation-collision-detector`, `D-20260901-container-network-collision-safety`

---

## 暫停中

（目前無暫停中項目。）

## 歷史入口

- 決策：`docs/archive/decisions-2026-09.md`「事件記錄（event-time）」。
- 死路：`docs/archive/dead-ends-2026-08.md`「事件記錄（event-time）」。
- 里程碑：`docs/archive/milestones-2026-09.md`「事件記錄（event-time）」。
- legacy dead-end 的完整推導與實驗證據：`docs/dead-ends.md`「分工」。
- 無路徑線索時執行 `scripts/doc-governance.py find '自然語言問題或 stable ID'`；人工 pointer 不作為可檢索性的代理。

## 待辦入口

- 未結案項目以 `docs/backlog.md` 為 canonical state；用 `B-*` stable ID 定位。

## 移交準備度

(個人 infra,暫無移交打算——平時留空)
