@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "APP_DIR=%ROOT%app"
set "PUBSPEC=%APP_DIR%\pubspec.yaml"
set "BUILD_SCRIPT=%ROOT%build_release.bat"
set "APK_PATH=%APP_DIR%\build\app\outputs\flutter-apk\app-release.apk"
set "GH_BIN=C:\Program Files\GitHub CLI\gh.exe"

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

echo.
echo Release published:
echo https://github.com/cwen0224/omini-location/releases/tag/%TAG%
exit /b 0
