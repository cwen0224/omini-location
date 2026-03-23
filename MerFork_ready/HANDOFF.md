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

## 建議先建立的文件
- `PROJECT_INTAKE.md`
- `PROJECT_BRIEF.md`
- `PROJECT_STRUCTURE.md`
- `INITIAL_CHECKLIST.md`
- `RELEASE_NOTES.md`
- `KNOWN_ISSUES.md`

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
