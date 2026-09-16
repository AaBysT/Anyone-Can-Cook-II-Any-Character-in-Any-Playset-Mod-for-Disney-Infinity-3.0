@echo off
setlocal
cd /d "%~dp0"
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_disney_infinity_3_mega_mod.ps1"
set "ERR=%ERRORLEVEL%"
echo.
if not "%ERR%"=="0" echo Installer exited with code %ERR%.
echo Press any key to close this window.
pause >nul
exit /b %ERR%