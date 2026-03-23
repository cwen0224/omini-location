# Supabase AI Access

這份文件說明如何讓 AI 直接抓 Supabase 報錯資料，不必靠人類手動複製。

## 核心原則
- AI 直接讀 Supabase 的 `app_errors`
- 人類只負責把資料送進系統，不負責把原始錯誤複製給 AI
- `docs/report-viewer.html` 是視覺化入口，不是唯一入口
- 如果條件允許，AI 應優先直接抓資料，再決定要不要看報表頁

## 最小必要設定
1. `supabase/schema.sql` 已套用
2. `public.app_errors` 有 `anon` 的 `select` 權限
3. `storage.objects` 的錯誤附件 bucket 可被讀取，或由回報頁提供公開 URL
4. `docs/report-viewer.html` 可直接讀最近回報

## AI 可以怎麼抓
- 直接開 `docs/report-viewer.html`
- 直接對 Supabase REST API 查詢 `app_errors`
- 先抓最新一筆，再依 `stack_trace`、`context_json`、`beacon_snapshot_json` 判讀

## AI 要看的順序
1. `stack_trace`
2. `context_json`
3. `beacon_snapshot_json`
4. `error_source`
5. `error_message`
6. 截圖

## 人類要做的事
- 不要把原始錯誤內容貼到聊天裡再請 AI 猜
- 不要跳過 `stack_trace`
- 不要把只有 UI 錯誤的資料當成完整 triage
- 只要確保 Supabase 權限與回報資料完整，AI 就能自己抓

## 如果 AI 抓不到
- 先檢查 `app_errors` 是否真的有資料
- 再檢查 `anon select` 是否存在
- 再檢查 report viewer 是否指到正確的 Supabase 專案
- 最後才懷疑 app 本身沒有上傳

## 對接手者的說明
這份流程的目標是把「人工 copy/paste」移出工作流。  
AI 應該可以直接從 Supabase 或 report viewer 取得錯誤，然後回到程式碼做修正。
