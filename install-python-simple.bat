@echo off
:: Simple Python Installation Script
:: Run as Administrator

echo ============================================
echo Python 3.11 Installation Script (Simple)
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

:: Download Python
echo Downloading Python 3.11.9...
echo.

curl -o "%TEMP%\python-installer.exe" "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"

if %errorLevel% neq 0 (
    echo ERROR: Failed to download Python installer
    pause
    exit /b 1
)

echo Download complete: OK
echo.

:: Install Python with bypass flags
echo Installing Python...
echo This may take a few minutes...
echo.

"%TEMP%\python-installer.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1 Include_tcltk=1 InstallLauncherAllUsers=1 CompileAll=1

if %errorLevel% equ 0 (
    echo.
    echo ============================================
    echo Python installation completed successfully!
    echo ============================================
    echo.
) else (
    echo.
    echo WARNING: Installation exited with code %errorLevel%
    echo.
)

:: Clean up
echo Cleaning up...
del "%TEMP%\python-installer.exe" 2>nul
echo.

:: Wait a moment for installation to complete
timeout /t 3 /nobreak >nul

:: Verify installation
echo Verifying installation...
echo.

python --version 2>nul
if %errorLevel% equ 0 (
    echo.
    echo ============================================
    echo VERIFICATION SUCCESSFUL!
    echo ============================================
    python --version
    python -m pip --version
    echo.
    echo Python is ready to use!
) else (
    echo.
    echo WARNING: Python command not found
    echo Please restart your terminal or computer
    echo.
)

echo.
echo Press any key to exit...
pause >nul
