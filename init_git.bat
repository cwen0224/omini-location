@echo off
setlocal

cd /d "%~dp0"

git init
if errorlevel 1 exit /b 1

git add .
if errorlevel 1 exit /b 1

git commit -m "Initial project setup"
if errorlevel 1 (
  echo.
  echo Git commit failed. You may need to configure git user.name and user.email first.
  echo Example:
  echo git config --global user.name "Your Name"
  echo git config --global user.email "you@example.com"
  exit /b 1
)

echo.
echo Local git repository initialized.
echo Next:
echo 1. Create a GitHub repository
echo 2. Add remote:
echo    git remote add origin https://github.com/YOUR_NAME/YOUR_REPO.git
echo 3. Push:
echo    git push -u origin main

