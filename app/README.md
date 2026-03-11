# 人權博物館APP骨架

目前已建立：
- Flutter 專案基本結構
- 首頁
- 感測器測試中心頁
- GPS / IMU / BLE Beacon / Camera 的能力占位模型

## 目前限制
這台機器目前沒有 `flutter` 指令，因此尚未執行：
- `flutter create`
- `flutter pub get`
- Android 專案生成
- APK 打包

## 下一步
當 Flutter SDK 安裝完成後，在 `app/` 目錄執行：

```powershell
flutter create .
flutter pub get
flutter run
```

接下來優先開發：
1. GPS 權限與定位頁
2. IMU 讀取頁
3. BLE Beacon 掃描頁
4. Camera 預覽頁
5. 裝置能力檢測與統一狀態模型

