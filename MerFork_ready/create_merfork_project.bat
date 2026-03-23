@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%scripts\bootstrap-new-repo.ps1"

if not exist "%PS1%" (
  echo Could not find bootstrap script:
  echo   %PS1%
  exit /b 1
)

set "PROJECT_TITLE=%~1"
if "%PROJECT_TITLE%"=="" (
  set /p PROJECT_TITLE=Enter the new project name: 
)

if "%PROJECT_TITLE%"=="" (
  echo No project name provided.
  exit /b 1
)
set "PROJECT_TITLE=%PROJECT_TITLE:"=%"

for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$name = $env:PROJECT_TITLE.Trim(); if ([string]::IsNullOrWhiteSpace($name)) { '' } else { (($name -replace '[<>:\"/\\|?*]', '-' -replace '\s+','-').Trim('-')) }"`) do set "PROJECT_SLUG=%%I"

if "%PROJECT_SLUG%"=="" (
  echo No valid project folder name could be derived from:
  echo   %PROJECT_TITLE%
  exit /b 1
)

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

set "TARGET_ROOT=%PARENT_DIR%\%PROJECT_SLUG%"

set "REPO_NAME=%~3"
if "%REPO_NAME%"=="" (
  set /p REPO_NAME=Enter GitHub repo name [%PROJECT_SLUG%]: 
)
if "%REPO_NAME%"=="" (
  set "REPO_NAME=%PROJECT_SLUG%"
)
set "REPO_NAME=%REPO_NAME:"=%"

set "REPO_URL=%~4"
if "%REPO_URL%"=="" (
  set /p REPO_URL=Enter GitHub repo URL (optional): 
)
set "REPO_URL=%REPO_URL:"=%"

set "REPO_VISIBILITY=%~5"
if "%REPO_VISIBILITY%"=="" (
  set /p REPO_VISIBILITY=Repo visibility [private/public] [private]: 
)
if "%REPO_VISIBILITY%"=="" (
  set "REPO_VISIBILITY=private"
)
set "REPO_VISIBILITY=%REPO_VISIBILITY:"=%"

if exist "%TARGET_ROOT%" (
  echo Target folder already exists:
  echo   %TARGET_ROOT%
  exit /b 1
)

set "PROJECT_GOAL="
set /p PROJECT_GOAL=Project goal / one-liner: 

set "TARGET_USERS="
set /p TARGET_USERS=Target users (comma separated): 

set "CORE_FEATURES="
set /p CORE_FEATURES=Core features (comma separated): 

set "TECH_STACK="
set /p TECH_STACK=Tech stack: 

set "RELEASE_STRATEGY="
set /p RELEASE_STRATEGY=Release strategy: 

set "DATA_STRATEGY="
set /p DATA_STRATEGY=Data / report strategy: 

set "USE_PROTOCOL="
set /p USE_PROTOCOL=Use MerFork Protocol? [Y/N]: 

if /I "%USE_PROTOCOL%"=="Y" (
  set "USE_PROTOCOL=Yes"
) else if /I "%USE_PROTOCOL%"=="N" (
  set "USE_PROTOCOL=No"
)

set "INIT_GIT="
set /p INIT_GIT=Initialize git in the new folder? [Y/N]: 
if /I "%INIT_GIT%"=="Y" (
  set "INIT_GIT_FLAG=-InitializeGit"
) else (
  set "INIT_GIT_FLAG="
)

echo.
echo Review the intake summary:
echo   Project title   : %PROJECT_TITLE%
echo   Folder slug     : %PROJECT_SLUG%
echo   Repo name       : %REPO_NAME%
echo   Repo URL        : %REPO_URL%
echo   Repo visibility : %REPO_VISIBILITY%
echo   Parent folder   : %PARENT_DIR%
echo   Target root     : %TARGET_ROOT%
echo   Project goal    : %PROJECT_GOAL%
echo   Target users    : %TARGET_USERS%
echo   Core features   : %CORE_FEATURES%
echo   Tech stack      : %TECH_STACK%
echo   Release strategy: %RELEASE_STRATEGY%
echo   Data strategy   : %DATA_STRATEGY%
echo   MerFork Protocol: %USE_PROTOCOL%
echo   Initialize git  : %INIT_GIT%
echo.
set "PROCEED="
set /p PROCEED=Proceed with scaffold generation? [Y/N]: 
if /I not "%PROCEED%"=="Y" (
  echo Aborted.
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -TargetRoot "%TARGET_ROOT%" -ProjectName "%PROJECT_TITLE%" -RepositoryName "%REPO_NAME%" -RepositoryUrl "%REPO_URL%" -RepositoryVisibility "%REPO_VISIBILITY%" -ProjectGoal "%PROJECT_GOAL%" -TargetUsers "%TARGET_USERS%" -CoreFeatures "%CORE_FEATURES%" -TechStack "%TECH_STACK%" -ReleaseStrategy "%RELEASE_STRATEGY%" -DataStrategy "%DATA_STRATEGY%" -UseMerForkProtocol "%USE_PROTOCOL%" %INIT_GIT_FLAG%
if errorlevel 1 exit /b 1

echo.
echo Done.
echo Project name: %PROJECT_TITLE%
echo Project folder: %PROJECT_SLUG%
echo Repo name: %REPO_NAME%
echo New MerFork project created at: %TARGET_ROOT%
endlocal
