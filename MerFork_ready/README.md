# MerFork Ready Project

這個子資料夾是新專案的起點模板，給下一位 AI 或工程師直接接手用。

它的定位不是主專案，而是一個「可以直接開新案」的工作區入口。  
如果你要開另外一個 MerFork ready 專案，先從這裡開始，不要直接改主專案根目錄。

## 先讀這三份
1. [`START_HERE.md`](./START_HERE.md)
2. [`HANDOFF.md`](./HANDOFF.md)
3. [`PROJECT_STRUCTURE.md`](./PROJECT_STRUCTURE.md)
4. 如果你不熟這套系統，先讀 [`SETUP_WITH_AI.md`](./SETUP_WITH_AI.md)

## 先用這個腳本
- [`create_merfork_project.bat`](./create_merfork_project.bat)
- 或 [`scripts/bootstrap-new-repo.ps1`](./scripts/bootstrap-new-repo.ps1)
- 它會先問使用者必要資訊，包含 repo 層級資訊、產品目標、技術棧與發版策略
- 它會先問使用者必要資訊，包含 repo 層級資訊、產品目標、技術棧、發版策略，以及哪些地方要交給 AI 決定
- 它可以把這個模板複製到你指定的新 repo 根目錄，並可選擇直接初始化 git
- 它會生成 `PROJECT_INTAKE.md` 與填好的 `PROJECT_BRIEF.md`，讓下一位 AI 直接接手

## 這個資料夾的使用方式
- 把新專案的產品目標、技術選型、發版策略先寫進來
- 把所有固定流程寫成可重複執行的步驟
- 把每次接手時需要知道的坑、版本、外部服務依賴都留在這裡

## 與主專案的關係
- 主專案仍然在 repo 根目錄
- `MerFork_ready/` 是新專案模板
- 這裡的內容可複製到新的 repo 或新的工作目錄
- 真正開始新的人魚專案時，請建立獨立的新 GitHub repo，不要直接在這個主 repo 上長分支混做
