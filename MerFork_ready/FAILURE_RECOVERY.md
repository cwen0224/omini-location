# Failure Recovery

這份文件定義 MerFork 出問題時的復原順序。

## 來源真相順序
1. `app/pubspec.yaml`
2. `docs/version.json`
3. `docs/index.html`
4. `supabase/schema.sql`
5. `docs/report-viewer.html`
6. `build_release.bat`
7. `publish_github_release.bat`

## 發版失敗時先看什麼
- 先看 `logs/build_release.log`
- 再看 `publish_github_release.bat` 的檢查步驟
- 如果 release asset 沒上去，先確認 `docs/version.json` 是否已跟 `pubspec.yaml` 同步
- 如果手機看不到新版本，先確認 GitHub Pages 已更新

## Supabase 回報看不到時先看什麼
- `supabase/schema.sql` 是否真的已套用
- `app_errors` 是否有匿名 select policy
- `docs/report-viewer.html` 的查詢是否包含 `stack_trace`
- 報錯資料裡是否真的有 `context_json`

## 回復策略
- 如果只是版本不同步，先修版本檔，不要直接改程式
- 如果只是 release 壞掉，先修發版鏈，不要重構 app
- 如果只是報錯頁看不到資料，先修 Supabase 權限和查詢
- 如果只是單一功能壞掉，先用 app_errors 的 stack trace 找到最小範圍

## AI 的工作方式
- 先判斷是 app 問題、發版問題、還是資料問題
- 只修一個層次，不要一次修三層
- 每次修正後都要驗證同一筆報錯是否消失

## 不要這樣做
- 不要先刪資料
- 不要先重建整個 repo
- 不要把暫時 workaround 當正式修法
- 不要在沒有驗證前就宣告修好
