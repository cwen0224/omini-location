# GitHub Pages 發布說明

目前已建立：
- `docs/index.html`：下載頁
- `docs/downloads/`：放置 APK 的資料夾

## 你要做的事
1. 執行 `build_apk.bat`
2. 執行 `init_git.bat`
3. 建立 GitHub repo
4. 把這個專案 push 上去
5. 在 repo 設定中啟用 GitHub Pages，來源選 `Deploy from a branch`
6. 分支選 `main`，資料夾選 `/docs`

## 之後的網址
GitHub Pages 會是：

`https://你的帳號.github.io/你的repo名/`

下載按鈕會指向：

`https://你的帳號.github.io/你的repo名/downloads/app-release.apk`

## 注意
- GitHub Pages 只負責顯示下載頁與提供檔案下載
- 真正安裝仍是 Android 側載 APK
- 若之後改用 GitHub Releases，可把 `index.html` 的下載連結改成 Release asset
