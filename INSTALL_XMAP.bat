@echo off
setlocal

set "PS_EXE=powershell"
set "NEED_PAUSE=1"
where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    set "PS_EXE=pwsh"
)

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL_XMAP.ps1" %*
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
    echo Installation finished with exit code 0.
) else (
    echo Installation failed with exit code %EXIT_CODE%.
)

if "%NEED_PAUSE%"=="1" (
    pause
)

endlocal & exit /b %EXIT_CODE%
