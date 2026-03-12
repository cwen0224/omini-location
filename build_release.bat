@echo off
setlocal

set "ROOT=%~dp0"
set "FLUTTER_BIN=C:\Users\Sang\flutter\bin\flutter.bat"
set "LOG_DIR=%ROOT%logs"
set "LOG_FILE=%LOG_DIR%\build_release.log"
set "GRADLE_USER_HOME=%ROOT%.gradle-user-home"
set "ANDROID_DIR=%ROOT%app\android"
set "DEX_DIR=%ROOT%app\build\app\intermediates\dex\release"
set "APK_DIR=%ROOT%app\build\app\outputs\flutter-apk"
set "RELEASE_APK=%APK_DIR%\app-release.apk"
set "PUBLISH_DIR=%ROOT%docs\downloads"
set "PUBLISH_APK=%PUBLISH_DIR%\app-release.apk"

if not exist "%FLUTTER_BIN%" (
  echo Flutter not found at:
  echo %FLUTTER_BIN%
  exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%"

if not exist "%ROOT%app" (
  echo App folder not found:
  echo %ROOT%app
  exit /b 1
)

cd /d "%ROOT%app"

echo ==== RELEASE BUILD START %date% %time% ==== > "%LOG_FILE%"
echo ROOT=%ROOT% >> "%LOG_FILE%"
echo GRADLE_USER_HOME=%GRADLE_USER_HOME% >> "%LOG_FILE%"
echo STOP GRADLE DAEMON >> "%LOG_FILE%"
pushd "%ANDROID_DIR%"
call gradlew.bat --stop >> "%LOG_FILE%" 2>&1
popd
echo CLEAN RELEASE DEX >> "%LOG_FILE%"
if exist "%DEX_DIR%" rmdir /s /q "%DEX_DIR%" >> "%LOG_FILE%" 2>&1
echo CLEAN APK OUTPUTS >> "%LOG_FILE%"
if exist "%APK_DIR%" rmdir /s /q "%APK_DIR%" >> "%LOG_FILE%" 2>&1
call "%FLUTTER_BIN%" doctor >> "%LOG_FILE%" 2>&1
if errorlevel 1 goto build_failed
call "%FLUTTER_BIN%" pub get >> "%LOG_FILE%" 2>&1
if errorlevel 1 goto build_failed
call "%FLUTTER_BIN%" build apk --release -v >> "%LOG_FILE%" 2>&1
if errorlevel 1 goto build_failed
if not exist "%PUBLISH_DIR%" mkdir "%PUBLISH_DIR%"
if exist "%RELEASE_APK%" (
  echo COPY APK TO DOCS >> "%LOG_FILE%"
  copy /Y "%RELEASE_APK%" "%PUBLISH_APK%" >> "%LOG_FILE%" 2>&1
)
echo. >> "%LOG_FILE%"
echo ==== RELEASE BUILD END %date% %time% ==== >> "%LOG_FILE%"

echo.
echo Finished. Log saved to:
echo %LOG_FILE%
if exist "%PUBLISH_APK%" (
  echo Published APK:
  echo %PUBLISH_APK%
)
exit /b 0

:build_failed
echo. >> "%LOG_FILE%"
echo ==== RELEASE BUILD FAILED %date% %time% ==== >> "%LOG_FILE%"
echo.
echo Release build failed. See log:
echo %LOG_FILE%
exit /b 1
