@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "APP_DIR=%ROOT%app"
set "PUBSPEC=%APP_DIR%\pubspec.yaml"
set "BUILD_SCRIPT=%ROOT%build_release.bat"
set "APK_PATH=%APP_DIR%\build\app\outputs\flutter-apk\app-release.apk"
set "GH_BIN=C:\Program Files\GitHub CLI\gh.exe"
set "GIT_BIN=git"

if not exist "%GH_BIN%" (
  echo GitHub CLI not found:
  echo %GH_BIN%
  exit /b 1
)

if not exist "%PUBSPEC%" (
  echo pubspec.yaml not found:
  echo %PUBSPEC%
  exit /b 1
)

%GIT_BIN% rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
  echo This script must be run inside the git repository.
  exit /b 1
)

%GIT_BIN% diff --quiet -- app/pubspec.yaml docs/version.json docs/index.html
if errorlevel 1 (
  echo Version files have uncommitted changes.
  echo Commit and push app/pubspec.yaml, docs/version.json, and docs/index.html first.
  exit /b 1
)

%GIT_BIN% diff --cached --quiet -- app/pubspec.yaml docs/version.json docs/index.html
if errorlevel 1 (
  echo Version files are staged but not committed.
  echo Commit and push app/pubspec.yaml, docs/version.json, and docs/index.html first.
  exit /b 1
)

for /f "delims=" %%L in ('%GIT_BIN% rev-parse HEAD 2^>nul') do set "LOCAL_HEAD=%%L"
for /f "delims=" %%R in ('%GIT_BIN% rev-parse @{u} 2^>nul') do set "UPSTREAM_HEAD=%%R"

if not defined LOCAL_HEAD (
  echo Failed to resolve local git HEAD.
  exit /b 1
)

if not defined UPSTREAM_HEAD (
  echo Failed to resolve upstream branch.
  echo Push this branch to origin first.
  exit /b 1
)

if /I not "%LOCAL_HEAD%"=="%UPSTREAM_HEAD%" (
  echo Local branch is not pushed to upstream.
  echo Push app/pubspec.yaml, docs/version.json, and docs/index.html before publishing release assets.
  exit /b 1
)

for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "(Select-String -Path '%PUBSPEC%' -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()"`) do (
  set "VERSION_RAW=%%V"
)

if not defined VERSION_RAW (
  echo Failed to read version from:
  echo %PUBSPEC%
  exit /b 1
)

set "TAG=v%VERSION_RAW%"
set "RELEASE_TITLE=%TAG%"
set "RELEASE_NOTES=Automated release for %TAG%"

echo Checking GitHub authentication...
"%GH_BIN%" auth status >nul 2>&1
if errorlevel 1 (
  echo GitHub CLI is not authenticated.
  echo Run: gh auth login
  exit /b 1
)

echo Building release APK...
call "%BUILD_SCRIPT%"
if errorlevel 1 exit /b 1

if not exist "%APK_PATH%" (
  echo Release APK not found:
  echo %APK_PATH%
  exit /b 1
)

echo Publishing %TAG% to GitHub Releases...
"%GH_BIN%" release view "%TAG%" >nul 2>&1
if errorlevel 1 (
  "%GH_BIN%" release create "%TAG%" "%APK_PATH%" --title "%RELEASE_TITLE%" --notes "%RELEASE_NOTES%"
  if errorlevel 1 exit /b 1
) else (
  "%GH_BIN%" release upload "%TAG%" "%APK_PATH%" --clobber
  if errorlevel 1 exit /b 1
)

if exist "%APK_PATH%" (
  del /f /q "%APK_PATH%"
)

echo.
echo Release published:
echo https://github.com/cwen0224/omini-location/releases/tag/%TAG%
echo Local APK cleaned:
echo %APK_PATH%
exit /b 0
