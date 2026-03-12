# Supabase 設定說明

這一版先建立資料模型與 App 端配置入口，尚未真正連上 Supabase。

## 你之後要提供的資料
- Supabase Project URL
- Supabase anon key
- 是否允許匿名上傳
- 是否需要登入機制

## App 端設定入口
檔案：`app/lib/core/remote_backend_config.dart`

目前預設：
- `enabled = false`
- `provider = supabase`
- `supabaseUrl = ''`
- `supabaseAnonKey = ''`

填完後，下一步即可開始串接：
- `app_errors`
- `beacon_registry`
- `test_sessions`
- `Storage buckets`

## 建議資料流
1. App 錯誤 -> `app_errors`
2. Beacon 命名資料 -> `beacon_registry`
3. 測試 Session -> `test_sessions`
4. AR 錄影 / 截圖 -> `Storage`
5. Storage URL -> 回寫 `test_sessions` 或 `app_errors`

## 建議下一步
1. 在 Supabase 建專案
2. 執行 `supabase/schema.sql`
3. 建立 storage buckets
4. 將 URL / key 填入 `remote_backend_config.dart`
5. 實作 App 端 upload service
