@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%scripts\bootstrap-new-repo.ps1"

if not exist "%PS1%" (
  echo Could not find bootstrap script:
  echo   %PS1%
  exit /b 1
)

set "TARGET_ROOT=%~1"
if "%TARGET_ROOT%"=="" (
  set /p TARGET_ROOT=Enter the new project folder path: 
)

if "%TARGET_ROOT%"=="" (
  echo No target path provided.
  exit /b 1
)

set "INIT_GIT="
set /p INIT_GIT=Initialize git in the new folder? [Y/N]: 
if /I "%INIT_GIT%"=="Y" (
  set "INIT_GIT_FLAG=-InitializeGit"
) else (
  set "INIT_GIT_FLAG="
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -TargetRoot "%TARGET_ROOT%" %INIT_GIT_FLAG%
if errorlevel 1 exit /b 1

echo.
echo Done.
echo New MerFork project created at: %TARGET_ROOT%
endlocal
