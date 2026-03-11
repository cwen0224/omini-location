@echo off
setlocal

set "FLUTTER_BIN=C:\Users\Sang\flutter\bin\flutter.bat"

if not exist "%FLUTTER_BIN%" (
  echo Flutter not found at:
  echo %FLUTTER_BIN%
  exit /b 1
)

cd /d "%~dp0app"

call "%FLUTTER_BIN%" pub get
if errorlevel 1 exit /b 1

call "%FLUTTER_BIN%" build apk --release
if errorlevel 1 exit /b 1

cd /d "%~dp0"

if not exist "docs\downloads" mkdir "docs\downloads"
copy /Y "app\build\app\outputs\flutter-apk\app-release.apk" "docs\downloads\app-release.apk"
if errorlevel 1 exit /b 1

echo.
echo APK built successfully.
echo Output:
echo %~dp0docs\downloads\app-release.apk

