# 人權博物館APP AI接手開發計畫

## 0. MerFork Protocol
本專案的更新、發版、問題回報、版本同步與驗證流程，統一稱為 `MerFork Protocol`。

這個名稱不是單一腳本，而是整套可重複執行的工作流，包含：
- 本機 build
- 版本號同步
- GitHub Release 發版
- GitHub Pages 下載頁更新
- Supabase 問題回報與查看頁

接手者若在文件、聊天室或 commit 中看到 `MerFork Protocol`，一律視為這整條更新鏈，不要拆成零散步驟理解。

## 1. 文件目的
本文件提供後續 AI 助手或工程師直接接手開發「人權博物館APP」時所需的完整工作脈絡、技術決策方向、開發順序與驗收基準。

本專案不是一般內容型 App，核心需求包含以下手機原生能力整合：
- GPS 定位
- 陀螺儀 / 加速度計 / IMU / 羅盤儀
- BLE Beacon 掃描
- 攝影機
- 多感測器融合定位
- 室內外混合定位
- AR 指引與地圖導覽

因此本專案不建議只做純 PWA。應以可安裝的原生能力 App 為主，並搭配可動態更新的內容架構。

## 2. 專案目標
建立一套可在博物館室內外使用的手機 App，支援：
- 開發者模式：現場蒐資、建圖、Beacon 校正、資料版本管理
- 使用者模式：地圖定位、AR 指引、位置綁定訊息、導覽觸發
- 感測器融合：GPS + Camera + BLE + IMU
- 後續可擴充為內容動態更新，不必每次都重新安裝 APK

## 3. 核心結論
### 3.1 是否可以先準備感測器能力
可以先準備，而且應該優先準備。第一階段先把原生能力與權限、資料流、測試頁面建起來，再進入融合定位與場域建圖。

### 3.2 建議技術路線
建議採用：
- App 框架：Flutter
- Android 為第一優先平台
- iOS 為第二階段
- 內容更新：遠端設定 + API/JSON 下載
- 感測器資料層：原生插件或平台通道整合

選擇 Flutter 的原因：
- 跨平台能力完整
- 對相機、GPS、IMU、BLE 都有成熟插件生態
- UI 開發快，適合先做 MVP
- 後續若要包 Android APK 測試版最直接

備選：
- React Native + 原生模組

不建議作為主線：
- 純網頁/PWA，因為 BLE、背景能力、相機追蹤、感測器整合與 AR 能力會受限制

### 3.5 正式定位核心方向
目前已確認後續正式定位核心不應延續頁面級 heuristic，應改採：
- `IMU prediction`
- `GPS / BLE / compass / camera measurement update`
- `EKF / Error-State KF`
- `quality-driven fusion`
- `indoor / transition / outdoor handover`

已建立的第一批程式骨架在：
- `app/lib/domain/localization/`

接手者應把這一層視為後續正式定位主線，而不是再從測試頁重新發明一套定位邏輯。

### 3.3 開發效率優先原則
後續 AI 或工程師接手時，請直接遵守以下規則：
- 優先維持 Android 可安裝、可更新、可真機測試，再擴充功能。
- 若可由代理直接執行，不要把本地 build、git、版本同步等工作丟給使用者手動完成。
- 若需要使用者在本機執行，優先提供單一 `.bat` 腳本，不要求輸入長命令。
- 每次對外可見更新都要同步升版本號，不能只換 APK 檔內容。
- 所有交接資訊需寫回文件，不可只存在聊天紀錄。

### 3.4 已知環境限制
- Windows + Android/Gradle 在中文專案路徑下曾出現建置失敗，因此專案已搬到 `C:\Users\Sang\Desktop\human_rights_museum_app`。
- 後續建置、git 操作、版本更新均應以此英文路徑為主，不要再切回中文路徑工作。
- Windows 曾出現 Gradle/Java 檔案鎖，固定流程是先 `gradlew --stop`，再清除 dex 與 APK outputs，最後 build。

## 4. 建議系統架構
### 4.1 App 分層
- Presentation Layer
  - 首頁
  - 地圖頁
  - AR 指引頁
  - 感測器測試頁
  - 訊息紀錄頁
  - 開發者模式頁
- Domain Layer
  - 定位狀態管理
  - 感測器融合邏輯
  - 模式切換邏輯
  - 信心分數計算
  - 重定位流程
- Data Layer
  - GPS Provider
  - IMU Provider
  - BLE Scanner
  - Camera Tracking Provider
  - Local Cache
  - Remote Config / API

### 4.2 後端與資料策略
第一階段可先做本地假資料與 JSON 檔案驅動。

第二階段再補：
- 地圖資料 API
- 訊息紀錄 API
- 地圖版本 API
- 內容更新 API

### 4.3 更新策略
App 安裝一次後，後續更新以兩種層次處理：
- 內容更新：地圖、文案、展點、導覽、Beacon 設定，由伺服器下載
- 安裝包更新：原生功能有重大變更時才重新發布 APK

### 4.4 更新包策略
建議採雙層更新：
- App Update Manifest
  - 提供最新 `app_version`、`build_number`、`apk_url`、`release_notes`、`force_update`
- Content Package Manifest
  - 提供 `content_version`、`package_url`、`checksum`、`package_type`

接手 AI 應避免把所有更新都做成重裝 APK。
原則如下：
- 原生能力或插件變更：重發 APK
- 展點、地圖、Beacon、文案、遠端設定：走內容更新包

### 4.5 已完成的更新機制基線
目前專案已具備：
- GitHub Pages 下載頁
- GitHub Releases APK 檔案來源
- 遠端 `version.json` 版本檢查
- App 內更新卡片與更新內容顯示
- App 內直接下載 APK
- Android 原生安裝器呼叫
- 未知來源安裝權限引導
- 更新前清理舊 APK 暫存

接手者不應退回成「只有外部下載頁」的流程，除非 Android 系統限制或安全政策要求。

## 5. 感測器能力準備計畫
### 5.1 GPS
目標：
- 取得經緯度
- 取得更新頻率
- 取得精度資訊
- 處理室內弱訊號與不可用狀態

第一階段要做：
- 位置權限流程
- 前景定位測試頁
- 精度、速度、時間戳顯示
- 定位可用性狀態機

### 5.2 陀螺儀 / 加速度計 / IMU / 羅盤儀
目標：
- 取得加速度、角速度、朝向估計基礎資料
- 供之後 PDR / 姿態估計 / 穩定性判斷 / 朝向估計使用

第一階段要做：
- 感測器可用性檢測
- 即時數值顯示
- 磁力計 / 方位角顯示
- 取樣頻率測試
- 基本濾波與記錄能力

### 5.3 BLE Beacon
目標：
- 掃描附近 Beacon
- 顯示 UUID / Major / Minor / RSSI
- 記錄掃描結果
- 建立 Beacon 測試頁與場域校正基礎
- 支援 Beacon 命名與保存，供場域定位測試使用

第一階段要做：
- 藍牙權限流程
- 掃描頁
- Beacon 清單
- 訊號強度與更新時間顯示
- Android 版本相容處理

### 5.4 攝影機
目標：
- 提供拍攝預覽
- 後續供視覺定位、SLAM、AR 指引使用

第一階段要做：
- 相機權限流程
- 預覽頁
- 拍照或畫面串流測試
- 基本效能檢查

### 5.5 多感測器融合
目標：
- 建立統一資料結構
- 為後續 EKF/ESKF 留出介面

第一階段先不追求完整精度，只做：
- 時間戳對齊
- 各感測器健康狀態
- 品質分數欄位
- 簡化版融合狀態面板

## 6. 開發階段規劃
### Phase 0：專案初始化
目標：
- 建立 Flutter 專案
- 建立 Android 測試版環境
- 建立資料夾結構
- 建立基本 UI 架構

交付物：
- 可執行的 App 專案
- 首頁與導覽骨架
- 感測器功能占位頁面

### Phase 1：感測器能力驗證
目標：
- GPS / IMU / BLE / Camera 都能在 Android 裝置上正常呼叫

交付物：
- 感測器測試中心頁
- 每種感測器的測試頁
- 權限處理
- 錯誤狀態顯示

驗收標準：
- Android 手機可成功取得 GPS
- 可讀取 IMU 資料
- 可讀取磁力計與基本方位角
- 可掃描 BLE Beacon
- 可開啟攝影機預覽

### Phase 2：定位資料模型與狀態管理
目標：
- 將所有感測器輸出統一模型
- 建立定位狀態流

交付物：
- SensorReading model
- LocalizationState model
- Confidence score 欄位
- 感測器健康檢查機制
- Measurement model
- HandoverState model
- SensorQualityScores model
- EKF localization service skeleton

### Phase 3：地圖與導覽 MVP
目標：
- 顯示地圖
- 顯示目前位置
- 載入靜態展點資料

交付物：
- 地圖頁
- 展點列表
- 展點詳情
- 位置綁定訊息雛形

### Phase 4：BLE + GPS + IMU 基礎融合
目標：
- 完成基礎層定位 MVP

交付物：
- 基本室內外切換
- 信心分數顯示
- 漂移與失效提示
- prediction / update 流程接線
- BLE / compass / GPS measurement update

### Phase 5：Camera 視覺定位 / AR 指引
目標：
- 在可行條件下加入攝影機輔助定位與 AR 導覽

交付物：
- AR 指引頁
- Camera tracking 狀態
- 重定位入口

### Phase 6：動態內容更新
目標：
- App 開啟後自動抓取最新版內容

交付物：
- 遠端設定
- 地圖/展點/Beacon 設定 JSON 更新
- 本地快取與版本比對

### Phase 7：App 更新系統
目標：
- 使用者不需每次手動回下載頁找 APK
- App 可自動檢查是否有新版安裝包或內容更新包

交付物：
- Version manifest model
- 啟動時版本檢查
- 更新提示 UI
- APK 下載與安裝流程
- 內容更新包下載、checksum 驗證與套用

驗收標準：
- App 啟動時可顯示是否有新版 APK
- App 可顯示目前安裝版本與遠端最新版本
- App 可直接下載 APK 並開啟 Android 安裝器
- App 可套用內容更新包而不重裝 APK

## 7. AI 接手後的第一批工作
後續 AI 請優先執行以下事項，不要一開始就做複雜融合演算法：

1. 建立 Flutter Android App 專案骨架
2. 建立首頁與模式切換頁
3. 建立感測器測試中心頁
4. 先串接 GPS
5. 再串接 IMU
6. 再串接 BLE Beacon 掃描
7. 最後串接 Camera 預覽
8. 完成 Android 權限處理
9. 建立統一的 SensorReading / AppPermission / DeviceCapability 模型
10. 在真機上做基本功能驗證
11. 建立 App 更新 manifest 與內容更新 manifest 模型
12. 在 App 內實作版本檢查與更新提示流程

若專案不是從零開始，而是延續目前狀態，則請改依以下順序：
1. 先讀 `需求規格.md` 與本文件
2. 確認目前版本號、`docs/version.json`、`docs/index.html` 是否一致
3. 確認 `build_release.bat` 可成功產出並複製 APK
4. 先在真機驗證首頁、感測器頁、更新頁、回報頁
5. 再進入新功能開發

## 8. 建議資料夾結構
```text
app/
  lib/
    app/
    core/
    features/
      home/
      sensors/
      map/
      ar/
      messages/
      developer_mode/
    data/
    domain/
  android/
  assets/
  docs/
```

## 9. 感測器與權限注意事項
### Android 權限
至少需處理：
- Fine Location
- Coarse Location
- Camera
- Bluetooth Scan
- Bluetooth Connect
- Nearby Devices

部分 Android 版本對 BLE 與定位權限耦合較深，接手 AI 不應假設所有裝置表現一致，需把權限檢查、失敗提示與裝置能力檢測寫完整。

### BLE / Beacon 特別注意
- Android 掃描到的 `remoteId` 或 MAC 可能浮動，不能直接當作最終 Beacon 身分。
- 場域測試時應保留 manufacturer data、service data 與自定義 beacon key。
- 目前 App 已支援 Beacon 命名與保存，後續定位演算法應優先使用保存資料，而不是只看即時掃描 ID。

### 裝置差異
接手 AI 需要假設：
- 不同品牌手機對感測器頻率限制不同
- BLE 背景掃描能力不同
- 相機效能差異很大
- 室內 GPS 常不可用

## 10. 非功能設計要求
- 優先 Android 實機可測，不先追求雙平台完整性
- 先可用，再做高精度
- 所有感測器頁面都要有 debug 資訊
- 所有資料流都要帶時間戳
- 所有定位估計都要有 confidence 欄位
- 所有遠端內容要可版本控管
- 所有更新包都要帶版本號與 checksum
- 版本檢查失敗時不得阻塞 App 基本啟動
- 問題排查流程要優先依賴 App 內建回報，而不是要求使用者手動整理 log
- 頁面需支援小螢幕與底部手勢區，不可讓重要內容被遮擋
- 更新流程需有備援路徑；App 內更新失敗時仍可回到 GitHub Pages 下載頁

## 11. 不要先做的事
後續 AI 在第一輪不應優先投入以下項目：
- 不要先做 iOS 上架流程
- 不要先做複雜 3D 視覺特效
- 不要先接真正的 SLAM 大模型
- 不要先做完整後端
- 不要先做正式商店發布
- 不要先過度優化 UI 細節

## 12. 驗證策略
### 功能驗證
- 感測器是否可正常呼叫
- 權限是否能完整引導
- App 是否能在 Android 真機安裝
- 感測器資料是否持續更新
- App 內更新是否可下載 APK、啟動安裝器並處理未知來源安裝引導
- 問題回報是否能帶出最近事件、最近錯誤與保存 Beacon

### 場域驗證
- 室外 GPS 測試
- 室內 Beacon 掃描測試
- 攝影機預覽效能測試
- IMU 取樣穩定度測試

### 後續演算法驗證
- 室內外切換是否穩定
- 定位跳點是否可控
- 信心分數是否合理

## 13. 最終產品策略
本專案建議採：
- 首次安裝為 Android APK
- 後續內容由雲端動態更新
- QR Code 僅作為首次安裝入口或導流頁

這樣可以同時滿足：
- 能調用原生感測器
- 能快速現場安裝
- 後續打開時能取得最新內容

## 14. 固定工作流程
### 14.1 本地路徑
- 正式工作根目錄：`C:\Users\Sang\Desktop\human_rights_museum_app`
- 不要再以中文路徑作為 Android build 主路徑

### 14.2 建置腳本
- `app_debug.bat`
  - 停止 Gradle daemon
  - 清 debug dex / outputs
  - 執行 debug build
- `build_release.bat`
  - 停止 Gradle daemon
  - 清 release dex / outputs
  - 執行 release build
  - 產出 release APK，供後續上傳到 GitHub Release asset
- `publish_github_release.bat`
  - 檢查 `gh auth status`
  - 呼叫 `build_release.bat`
  - 依 `app/pubspec.yaml` 版本建立或更新 GitHub Release asset

### 14.3 發版規則
- 每次對外可見更新時必做：
  - 更新 `app/pubspec.yaml`
  - 更新 `docs/version.json`
  - 更新 `docs/index.html`
  - 重建 release APK
  - 執行 `publish_github_release.bat` 上傳 `app-release.apk` 到對應 GitHub Release asset
  - 確認 `apk_url` 指向對應 Release asset
  - commit / push
- 若未同步版本號，App 內版本檢查會失效，這是已確認的實務規則。

### 14.4 問題排查規則
- 優先看 App 內 `回報問題`
- 優先使用 App 右下角 `回報` 先保留當前畫面，再把截圖與除錯資訊一起上傳到 Supabase
- 優先看最近事件、最近錯誤、版本、已保存 Beacon
- 只有在 App 內資料不足時，才要求額外裝置 log

### 14.5 文件同步規則
- 新需求、新限制、新流程一旦定案，必須同步更新：
  - `需求規格.md`
  - `AI接手開發計畫.md`
- 目標是讓下一位 AI 或工程師不必重建上下文，就能直接繼續工作

## 15. 與需求規格文件關聯
接手 AI 應同步參考：
- `需求規格.md`
- `接手工作流與踩坑紀錄.md`

本文件是開發執行計畫；
`需求規格.md` 是需求與方向母文件。

若兩者衝突，優先處理方式如下：
1. 以 `需求規格.md` 的業務目標為準
2. 以本文件的技術執行順序為準
3. 新決策需同步更新兩份文件

## 16. 下一步建議
如果要正式開始開發，下一個 AI 或工程師應直接執行：

1. 建立 Flutter 專案
2. 先完成 Android 安裝與啟動
3. 做感測器測試中心頁
4. 在真機驗證 GPS / IMU / BLE / Camera
5. 建立 App 更新 manifest / 內容更新 manifest
6. 完成版本檢查與更新提示
7. 驗證後再進入定位融合與地圖功能

若延續目前版本，應改為：
1. 讀 `演算法重構方案.md`
2. 讀 `app/lib/domain/localization/`
3. 把 guided session 資料接到 quality score 計算
4. 實作 handover state machine
5. 把 EKF skeleton 接到 guided replay / localization pipeline

## 17. 實務交接文件
若接手者需要的不是產品方向，而是實際維運與發版細節，請優先讀：
- `接手工作流與踩坑紀錄.md`

該文件記錄的是：
- 真實發版順序
- GitHub Releases / GitHub Pages / Supabase 的實際鏈路
- 已踩過的 `.bat` / build / manifest / 回報流程問題
- 下一位接手時最容易誤判的地方
