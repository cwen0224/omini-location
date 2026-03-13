@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "FLUTTER_BIN=C:\Users\Sang\flutter\bin\flutter.bat"
set "LOG_DIR=%ROOT%logs"
set "LOG_FILE=%LOG_DIR%\build_release.log"
set "GRADLE_USER_HOME=%ROOT%.gradle-user-home"
set "ANDROID_DIR=%ROOT%app\android"
set "DEX_DIR=%ROOT%app\build\app\intermediates\dex\release"
set "APK_DIR=%ROOT%app\build\app\outputs\flutter-apk"
set "RELEASE_APK=%APK_DIR%\app-release.apk"

set "STEP=0"

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
call :run_step "Stop Gradle daemon" "pushd ""%ANDROID_DIR%"" && call gradlew.bat --stop && popd"
if errorlevel 1 goto build_failed

call :run_step "Clean release dex" "if exist ""%DEX_DIR%"" rmdir /s /q ""%DEX_DIR%"""
if errorlevel 1 goto build_failed

call :run_step "Clean APK outputs" "if exist ""%APK_DIR%"" rmdir /s /q ""%APK_DIR%"""
if errorlevel 1 goto build_failed

call :run_flutter_step "Flutter doctor" doctor
if errorlevel 1 goto build_failed

call :run_flutter_step "Flutter pub get" pub get
if errorlevel 1 goto build_failed

call :run_flutter_step "Flutter build apk --release -v" build apk --release -v
if errorlevel 1 goto build_failed

echo. >> "%LOG_FILE%"
echo ==== RELEASE BUILD END %date% %time% ==== >> "%LOG_FILE%"

echo.
echo Finished. Log saved to:
echo %LOG_FILE%
if exist "%RELEASE_APK%" (
  echo Release APK:
  echo %RELEASE_APK%
)
exit /b 0

:run_step
set /a STEP+=1
set "STEP_NAME=%~1"
set "STEP_CMD=%~2"

echo.
echo [Step !STEP!] !STEP_NAME!...
echo ==== STEP !STEP!: !STEP_NAME! ==== >> "%LOG_FILE%"
cmd /c "!STEP_CMD!" >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
  echo [Step !STEP!] FAILED: !STEP_NAME!
  exit /b 1
)
echo [Step !STEP!] Done: !STEP_NAME!
exit /b 0

:run_flutter_step
set /a STEP+=1
set "STEP_NAME=%~1"
shift

echo.
echo [Step !STEP!] !STEP_NAME!...
echo ==== STEP !STEP!: !STEP_NAME! ==== >> "%LOG_FILE%"
call "%FLUTTER_BIN%" %1 %2 %3 %4 %5 %6 %7 %8 %9 >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
  echo [Step !STEP!] FAILED: !STEP_NAME!
  exit /b 1
)
echo [Step !STEP!] Done: !STEP_NAME!
exit /b 0

:build_failed
echo. >> "%LOG_FILE%"
echo ==== RELEASE BUILD FAILED %date% %time% ==== >> "%LOG_FILE%"
echo.
echo Release build failed. See log:
echo %LOG_FILE%
exit /b 1
