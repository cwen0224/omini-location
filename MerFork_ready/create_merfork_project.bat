@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%scripts\bootstrap-new-repo.ps1"

if not exist "%PS1%" (
  echo Could not find bootstrap script:
  echo   %PS1%
  exit /b 1
)

set "PROJECT_NAME=%~1"
if "%PROJECT_NAME%"=="" (
  set /p PROJECT_NAME=Enter the new project name: 
)

if "%PROJECT_NAME%"=="" (
  echo No project name provided.
  exit /b 1
)
set "PROJECT_NAME=%PROJECT_NAME:"=%"
set "PROJECT_NAME=%PROJECT_NAME: =-%"

set "PARENT_DIR=%~2"
if "%PARENT_DIR%"=="" (
  set /p PARENT_DIR=Enter the parent folder for the new project [%USERPROFILE%\Desktop]: 
)

if "%PARENT_DIR%"=="" (
  set "PARENT_DIR=%USERPROFILE%\Desktop"
)

set "PARENT_DIR=%PARENT_DIR:"=%"

if not exist "%PARENT_DIR%" (
  echo Parent folder does not exist:
  echo   %PARENT_DIR%
  exit /b 1
)

set "TARGET_ROOT=%PARENT_DIR%\%PROJECT_NAME%"

if exist "%TARGET_ROOT%" (
  echo Target folder already exists:
  echo   %TARGET_ROOT%
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
echo Project name: %PROJECT_NAME%
echo New MerFork project created at: %TARGET_ROOT%
endlocal
