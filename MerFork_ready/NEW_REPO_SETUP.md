# New Repo Setup

如果這是新的 MerFork ready 專案，正確做法是先建立獨立的新 repo。

## 建 repo 的原因
- 避免和主專案共享歷史
- 避免版本號、發版流程、問題回報設定混在一起
- 讓下一位 AI 只接一個專案，不接兩個混雜狀態

## 建議流程
1. 在 GitHub 建立新的空 repo
2. 把 `MerFork_ready/` 內的模板複製到新 repo 根目錄
3. 重新寫 `PROJECT_BRIEF.md`
4. 重新寫 `HANDOFF.md`
5. 重新建立 build / release / update 流程
6. 把新 repo 的網址寫回文件

## 不要這樣做
- 不要直接在舊 repo 內另起一套完全不同的產品線
- 不要共用同一份 `version.json` 或 release asset 規則
- 不要讓下一個接手者猜哪個 commit 屬於哪個產品
