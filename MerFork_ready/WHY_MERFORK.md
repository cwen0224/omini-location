# Why MerFork

MerFork 的重點不是「又一套發版流程」。  
它的優勢是把更新鏈路壓縮成一個 AI 也能穩定執行的閉環：

1. GitHub Pages 放更新入口和版本資訊
2. Codex 只要改 `docs/version.json`、`docs/index.html` 和 release note，就能推新版
3. 手機端可以直接從 Pages 看更新，做到一鍵更新
4. GitHub Releases 只負責 APK 交付
5. 發版後本機 APK 會自動清掉，工作區保持乾淨
6. Supabase 的 app_errors 可以直接轉成修正計畫，不用人工猜
7. AI 可以自己抓 Supabase 報錯，不必等人類複製貼上

## 對 AI 的要求
- 先看 `docs/version.json`
- 先看 `docs/index.html`
- 先看 GitHub Pages 的下載頁
- 如果是要發新版，就先同步版本號，再跑 build，再跑 publish
- 不要跳過清理步驟

## 對接手者的要求
- 不要把 APK 當成長期文件保存
- 不要把 GitHub Releases 和 GitHub Pages 混成同一件事
- 不要手動複製版本資訊到多個地方
- 版本真相只保留一份，其他都是展示層

## 這套流程的名字
這套流程仍然叫 `MerFork Protocol`。  
它的實際價值是讓 AI 可以快速、安全、可回收地更新 App，讓手機端只要點一下就能拿到新版。
