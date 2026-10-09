@echo off
title AutoBrowse Setup
cd /d "%~dp0"
echo.
echo  AutoBrowse Setup
echo  ----------------
echo.

set "PY="
py -3 -c "import sys" >nul 2>nul && set "PY=py -3"
if not defined PY python -c "import sys" >nul 2>nul && set "PY=python"
if not defined PY (
    echo  Python was not found. Installing Python now, please wait...
    winget install -e --id Python.Python.3.12 --scope user --silent --accept-package-agreements --accept-source-agreements
    if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" set "PY="%LOCALAPPDATA%\Programs\Python\Python312\python.exe""
)
if not defined PY (
    echo.
    echo  Python could not be installed automatically.
    echo  Please install it from python.org, then run Setup.bat again.
    pause
    exit /b 1
)

echo  [1/4] Installing required libraries...
%PY% -m pip install --upgrade --quiet --disable-pip-version-check pip
%PY% -m pip install --upgrade --quiet --disable-pip-version-check pystray Pillow websockets customtkinter openpyxl pyinstaller
if errorlevel 1 (
    echo  Library installation failed. Check your internet connection and try again.
    pause
    exit /b 1
)

echo  [2/4] Building AutoBrowse.exe...
taskkill /f /im AutoBrowse.exe >nul 2>nul
%PY% -m PyInstaller --noconfirm --clean --onefile --windowed --name AutoBrowse --icon "AutoBrowse.ico" --collect-all customtkinter --add-data "AutoBrowse.ico;." "AutoBrowse.pyw" >build.log 2>&1
if not exist "dist\AutoBrowse.exe" (
    echo  Build failed. Details are in build.log
    pause
    exit /b 1
)
copy /y "dist\AutoBrowse.exe" "AutoBrowse.exe" >nul
rmdir /s /q build >nul 2>nul
rmdir /s /q dist >nul 2>nul
del /q AutoBrowse.spec build.log >nul 2>nul

echo  [3/4] Creating Desktop and Start Menu shortcuts...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$w = New-Object -ComObject WScript.Shell; $exe = (Resolve-Path 'AutoBrowse.exe').Path;" ^
 "foreach ($p in @([Environment]::GetFolderPath('Desktop'), (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'))) {" ^
 "$s = $w.CreateShortcut((Join-Path $p 'AutoBrowse.lnk')); $s.TargetPath = $exe; $s.WorkingDirectory = (Split-Path $exe);" ^
 "$s.IconLocation = $exe + ',0'; $s.Description = 'AutoBrowse'; $s.Save() }"

echo  [4/4] Starting AutoBrowse...
start "" "AutoBrowse.exe"
echo.
echo  Done. AutoBrowse is running. Look for its blue icon in the system tray.
echo  You can open it any time from the Desktop shortcut.
echo.
timeout /t 6 >nul
