@echo off
setlocal

set "ROOT=%~dp0"
set "FLUTTER_BIN=C:\Users\Sang\flutter\bin\flutter.bat"
set "LOG_DIR=%ROOT%logs"
set "LOG_FILE=%LOG_DIR%\app_run.log"
set "GRADLE_USER_HOME=%ROOT%.gradle-user-home"
set "ASCII_ROOT=C:\Users\Sang\Desktop\human_rights_museum_app"

if not exist "%FLUTTER_BIN%" (
  echo Flutter not found at:
  echo %FLUTTER_BIN%
  exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%"

if not exist "%ASCII_ROOT%" (
  cmd /c mklink /J "%ASCII_ROOT%" "%ROOT%" >nul 2>&1
)

if not exist "%ASCII_ROOT%\app" (
  echo Failed to prepare ASCII build path:
  echo %ASCII_ROOT%
  exit /b 1
)

cd /d "%ASCII_ROOT%\app"

echo ==== APP DEBUG START %date% %time% ==== > "%LOG_FILE%"
echo ASCII_ROOT=%ASCII_ROOT% >> "%LOG_FILE%"
echo GRADLE_USER_HOME=%GRADLE_USER_HOME% >> "%LOG_FILE%"
call "%FLUTTER_BIN%" doctor >> "%LOG_FILE%" 2>&1
call "%FLUTTER_BIN%" pub get >> "%LOG_FILE%" 2>&1
call "%FLUTTER_BIN%" build apk --debug -v >> "%LOG_FILE%" 2>&1
echo. >> "%LOG_FILE%"
echo ==== APP DEBUG END %date% %time% ==== >> "%LOG_FILE%"

echo.
echo Finished. Log saved to:
echo %LOG_FILE%
exit /b 0
