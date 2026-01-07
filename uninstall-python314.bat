@echo off
:: Uninstall Python 3.14 Script
:: Run as Administrator

echo ============================================
echo Python 3.14 Uninstall Script
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

:: Find Python 3.14 installation
echo Locating Python 3.14 installation...
echo.

set PYTHON314_PATH=C:\Users\Administrator\AppData\Local\Programs\Python\Python314

if exist "%PYTHON314_PATH%" (
    echo Found: %PYTHON314_PATH%
    echo.

    :: Check if uninstaller exists
    if exist "%PYTHON314_PATH%\python-3.14.2-amd64.exe" (
        echo Running uninstaller...
        "%PYTHON314_PATH%\python-3.14.2-amd64.exe" /uninstall /quiet
    ) else if exist "%PYTHON314_PATH%\uninstall.exe" (
        echo Running uninstaller...
        "%PYTHON314_PATH%\uninstall.exe" /quiet
    ) else (
        echo Uninstaller not found, removing directory manually...
        rmdir /s /q "%PYTHON314_PATH%"
    )

    echo.
    echo Python 3.14 removed from: %PYTHON314_PATH%
) else (
    echo Python 3.14 not found at expected location
)

:: Also check Program Files
set PYTHON314_PROGRAM=C:\Program Files\Python314

if exist "%PYTHON314_PROGRAM%" (
    echo Found: %PYTHON314_PROGRAM%
    echo Removing...
    rmdir /s /q "%PYTHON314_PROGRAM%"
    echo Removed: %PYTHON314_PROGRAM%
)

echo.
echo ============================================
echo Python 3.14 has been uninstalled
echo ============================================
echo.
echo Next steps:
echo 1. Run install-python311-simple.bat as Administrator
echo 2. Restart VS Code or terminal
echo.
echo Press any key to exit...
pause >nul
