# MerFork Ready Handoff

## 目的
這份文件讓下一位 AI 或工程師接手新專案時，不需要重新猜流程。

## 你要先確認的事
- 這是不是一個新的獨立 repo
- 這個專案的名稱
- 目前的最終發布目標
- 使用的技術棧
- 發版來源
- 問題回報來源
- 是否需要版本檢查與自動更新
- 你是不是直接打開資料夾的 AI

## 建議先建立的文件
- `PROJECT_INTAKE.md`
- `PROJECT_BRIEF.md`
- `PROJECT_STRUCTURE.md`
- `INITIAL_CHECKLIST.md`
- `RELEASE_NOTES.md`
- `KNOWN_ISSUES.md`
- `ERROR_TRIAGE.md`
- `FAILURE_RECOVERY.md`
- `SUPABASE_AI_ACCESS.md`

## 建議先收集的資訊
- 新專案名稱
- 獨立 GitHub repo 名稱
- repo URL
- repo visibility
- 專案目標
- 目標使用者
- 核心功能
- 技術棧
- 發版策略
- 資料 / 回報策略
- 哪些部分要 AI 幫忙決定
- 是否採用 MerFork Protocol

## MerFork Protocol
如果這個新專案也要沿用我們現在這套更新方式，就把整條流程叫做 `MerFork Protocol`。

MerFork 的核心優勢是：
- 版本資訊和下載頁放在 GitHub Pages，Codex 改完就能快速更新
- GitHub Releases 只負責 APK 交付
- 手機端可以從 Pages 一鍵取得新版
- 發版後本機 APK 會自動清掉，避免工作區堆滿安裝包
- Supabase 報錯可以直接轉成 AI 修正計畫
- AI 可以直接抓 Supabase 報錯，不必靠人類 copy/paste

流程至少要包含：
- 本機 build
- 版本號同步
- 發版
- 下載頁
- 問題回報
- 回報查看頁

## 接手規則
- 先讀文件，再改程式
- 先確保能發版，再做優化
- 不要把臨時決策留在聊天紀錄
- 每次改動要同步更新 `RELEASE_NOTES.md`
- 若是新的人魚專案，先在 GitHub 建新 repo，再把這套模板複製過去
- 如果你是 AI，先讀 `AI_FOLDER_START.md`，不要先找生成器
- 如果你看到 Supabase 的 `app_errors`，先讀 `ERROR_TRIAGE.md` 再開始修
- 如果你要直接抓 Supabase，先讀 `SUPABASE_AI_ACCESS.md`
