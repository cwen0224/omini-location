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
