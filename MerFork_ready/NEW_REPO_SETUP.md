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
雙擊根目錄的 `create_merfork_project.bat`，或用 PowerShell 直接呼叫：

```powershell
.\scripts\bootstrap-new-repo.ps1 -TargetRoot "C:\path\to\new-repo" -InitializeGit
```

BAT 會先問你：
1. 新專案名稱
2. 父資料夾路徑
3. Repo 名稱
4. Repo URL
5. Repo visibility
6. 專案目標
7. 目標使用者
8. 核心功能
9. 技術棧
10. 發版策略
11. 資料 / 回報策略
12. 是否採用 MerFork Protocol
13. 是否初始化 git

最後會自動建立 `父資料夾\專案名稱` 這個目錄。
如果專案名稱含空格，BAT 會自動把空格轉成 `-`；如果含 Windows 不允許的路徑字元，也會一併正規化成安全名稱。
它也會先列出一個摘要，讓你確認這些資訊沒有填錯再真的建立。

## 不要這樣做
- 不要直接在舊 repo 內另起一套完全不同的產品線
- 不要共用同一份 `version.json` 或 release asset 規則
- 不要讓下一個接手者猜哪個 commit 屬於哪個產品
