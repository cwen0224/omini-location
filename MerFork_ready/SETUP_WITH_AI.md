# Setup With AI

這份文件給不熟系統的人看。  
你不需要先懂 MerFork，也不需要先懂 repo、release 或資料回報。

## 你要做的事
1. 先建立一個新的 GitHub repo
2. 把 `MerFork_ready/` 複製到你的工作目錄，或直接在現成資料夾裡打開它
3. 如果已經有 AI 在協助，直接打開 `AI_FOLDER_START.md`
4. 把你知道的資訊填進去
5. 不知道的地方，讓 AI 幫你決定
6. 看摘要，確認沒有填錯，再開始執行

## 你可以交給 AI 的工作
- 幫你判斷 repo 名稱
- 幫你補 project goal
- 幫你整理 target users
- 幫你列 core features
- 幫你選技術棧
- 幫你決定 release strategy
- 幫你決定 data / report strategy
- 幫你整理 open questions
- 幫你決定哪些欄位需要先問使用者，哪些可以先用保守預設值

## 你可以直接對 AI 說
> 我現在要建立一個新的 MerFork ready 專案，但我不熟這套系統。  
> 請你根據我要做的產品，幫我逐項填寫起案資訊。  
> 如果某一項你也不確定，請直接列為 open questions，並給我一個保守的預設值。  
> 你要幫我完成的欄位包含：repo name、repo URL、visibility、project goal、target users、core features、tech stack、release strategy、data / report strategy、是否採用 MerFork Protocol。

## AI 應該怎麼幫
- 一次只問一個你真的需要知道的問題
- 如果可以合理推定，就先給預設值
- 不要用術語堆砌
- 對每個預設值附一句理由
- 把不確定的項目寫到 `PROJECT_INTAKE.md` 的 Open Questions

## 你不需要知道的技術細節
- 你不需要先懂 `build` 指令
- 你不需要先懂 release asset
- 你不需要先懂資料庫 schema
- 你不需要先懂版本號規則
- 你只要能說清楚這個專案要解決什麼問題

## 什麼時候可以開始寫程式
只有在這些內容已經大致填完之後才開始：
- `PROJECT_INTAKE.md`
- `PROJECT_BRIEF.md`
- `HANDOFF.md`
- `INITIAL_CHECKLIST.md`

如果你還沒填完，先讓 AI 幫你補，不要直接跳去改程式。

## 你不需要 BAT 也可以開始
如果你已經有一個現成資料夾，AI 直接讀 `AI_FOLDER_START.md` 和 `START_HERE.md` 就能開始，不需要先找生成器。
