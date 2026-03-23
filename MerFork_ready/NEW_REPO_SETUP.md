# New Repo Setup

如果這是新的 MerFork ready 專案，正確做法是先建立獨立的新 repo。

## 建 repo 的原因
- 避免和主專案共享歷史
- 避免版本號、發版流程、問題回報設定混在一起
- 讓下一位 AI 只接一個專案，不接兩個混雜狀態

## 建議流程
1. 在 GitHub 建立新的空 repo
2. 在本機把這份模板複製到新 repo 根目錄
3. 先跑 `scripts/bootstrap-new-repo.ps1`，把模板檔落到新 repo
4. 重新寫 `PROJECT_BRIEF.md`
5. 重新寫 `HANDOFF.md`
6. 重新建立 build / release / update 流程
7. 把新 repo 的網址寫回文件

## 建議啟動方式
如果你已經有一個新 repo 資料夾，AI 可以直接打開資料夾開始接手，不需要先跑任何生成器。

如果你是人類要建立新 repo，可用 PowerShell 直接呼叫：

```powershell
.\scripts\bootstrap-new-repo.ps1 -TargetRoot "C:\path\to\new-repo" -InitializeGit
```

## 如果你不熟這套系統
- 先打開 `SETUP_WITH_AI.md`
- 讓 AI 幫你填完那些你不確定的欄位
- 你只要提供你知道的部分，其他留給 AI 建議

## MerFork 的關鍵優勢
- GitHub Pages 放下載頁與版本資訊，Codex 改完就能快速更新
- GitHub Releases 只負責 APK 交付
- 手機端可以一鍵更新
- 發版完成後本機 APK 會自動清掉，避免安裝包堆積
- Supabase 報錯可以直接進 `ERROR_TRIAGE.md` 變成修正計畫
- 發版或回報失敗時可以直接照 `FAILURE_RECOVERY.md` 回復

## 不要這樣做
- 不要直接在舊 repo 內另起一套完全不同的產品線
- 不要共用同一份 `version.json` 或 release asset 規則
- 不要讓下一個接手者猜哪個 commit 屬於哪個產品
