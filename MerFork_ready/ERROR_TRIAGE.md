# Error Triage

這份文件告訴 AI，怎麼把 Supabase 的 `app_errors` 變成可執行的修正計畫。

## 讀取順序
1. 先看 `docs/report-viewer.html` 裡的最新回報
2. 先讀 `error_source`
3. 再讀 `error_message`
4. 接著讀 `stack_trace`
5. 再看 `context_json`
6. 最後看 `beacon_snapshot_json`

## 資料品質提醒
- 手動回報會把最新一筆錯誤的 `stack_trace` 與部分 context 一起送上來
- 如果 `stack_trace` 是空的，代表那次回報沒有抓到原始錯誤
- 如果 `context_json` 裡有 `latest_error_source`，優先沿用

## 判斷原則
- `stack_trace` 比 `error_message` 更重要
- `context_json` 比猜測更重要
- 如果有 `screenshot_url`，先看截圖
- 如果有 `session_id` 或 `segment_id`，回到對應流程看同一段
- 如果錯誤是 release / update / Pages 相關，先看發版鏈，不要先改 UI

## 常見對應區塊
- 截圖或截取失敗：
  - `app/lib/core/app_capture_service.dart`
- 地圖、軌跡、定位顯示：
  - `app/lib/features/sensors/`
  - `app/lib/features/testing/`
- 更新、版本、發版：
  - `app/pubspec.yaml`
  - `docs/version.json`
  - `docs/index.html`
  - `build_release.bat`
  - `publish_github_release.bat`
- Supabase 權限、表結構、RLS：
  - `supabase/schema.sql`
- 回報頁或下載頁 UI：
  - `docs/report-viewer.html`
  - `docs/index.html`
- 遠端同步或錯誤上報：
  - `app/lib/core/remote_sync_service.dart`

## AI 的輸出格式
AI 看完回報後，應該輸出：
1. 問題摘要
2. 可能的根因
3. 需要先看的檔案
4. 最小修正方案
5. 驗證步驟
6. 如果資料不足，還缺哪一個欄位

## 不要這樣做
- 不要只根據 `error_message` 猜
- 不要忽略 `stack_trace`
- 不要一開始就大改架構
- 不要把發版問題誤判成 app 邏輯問題
