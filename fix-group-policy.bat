@echo off
:: Fix Group Policy to Allow Python Installation
:: Run as Administrator

echo ============================================
echo Group Policy Fix for Python Installation
echo ============================================
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator!
    echo Right-click this file and select "Run as administrator"
    pause
    exit /b 1
)

echo Running as Administrator: OK
echo.

echo Disabling Windows Installer restrictions...
echo.

:: Remove Machine-level DisableMSI policy
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /t REG_DWORD /d 0 /f

:: Remove User-level DisableMSI policy
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /f 2>nul
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /t REG_DWORD /d 0 /f

:: Allow user installs
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableUserInstalls /t REG_DWORD /d 0 /f

echo.
echo Policies updated successfully!
echo.

echo Refreshing Group Policy...
gpupdate /force

echo.
echo ============================================
echo Group Policy Fix Complete!
echo ============================================
echo.
echo Next steps:
echo 1. Run: install-python311-simple.bat as Administrator
echo 2. If still blocked, restart your computer and try again
echo.
echo Press any key to exit...
pause >nul
