# Python 3.11 Installation Script with Bypass Flags
# Run this script as Administrator

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Python 3.11 Installation Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Running as Administrator: OK" -ForegroundColor Green
Write-Host ""

# Set execution policy temporarily
Write-Host "Setting execution policy..." -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Write-Host "Execution policy set: OK" -ForegroundColor Green
Write-Host ""

# Python version to install
$pythonVersion = "3.11.9"
$pythonInstallerUrl = "https://www.python.org/ftp/python/$pythonVersion/python-$pythonVersion-amd64.exe"
$installerPath = "$env:TEMP\python-$pythonVersion-installer.exe"

Write-Host "Downloading Python $pythonVersion..." -ForegroundColor Yellow
Write-Host "URL: $pythonInstallerUrl" -ForegroundColor Gray
Write-Host ""

try {
    # Download Python installer
    Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "Download complete: OK" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: Failed to download Python installer" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit 1
}

# Verify download
if (-not (Test-Path $installerPath)) {
    Write-Host "ERROR: Installer file not found at $installerPath" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "Installer downloaded to: $installerPath" -ForegroundColor Green
Write-Host ""

# Installation arguments with bypass flags
$installArgs = @(
    "/quiet",                    # Silent installation
    "InstallAllUsers=1",         # Install for all users
    "PrependPath=1",             # Add to PATH
    "Include_test=0",            # Skip tests
    "Include_doc=0",             # Skip documentation
    "Include_pip=1",             # Include pip
    "Include_tcltk=1",           # Include tkinter
    "InstallLauncherAllUsers=1", # Install launcher for all users
    "CompileAll=1"               # Compile all .py files
)

Write-Host "Installing Python $pythonVersion..." -ForegroundColor Yellow
Write-Host "Installation arguments:" -ForegroundColor Gray
$installArgs | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
Write-Host ""
Write-Host "This may take a few minutes. Please wait..." -ForegroundColor Yellow
Write-Host ""

try {
    # Run installer with bypass flags
    $process = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0) {
        Write-Host "============================================" -ForegroundColor Green
        Write-Host "Python installation completed successfully!" -ForegroundColor Green
        Write-Host "============================================" -ForegroundColor Green
        Write-Host ""
    } elseif ($process.ExitCode -eq 1602) {
        Write-Host "WARNING: Installation was cancelled by user" -ForegroundColor Yellow
        Write-Host "Exit Code: $($process.ExitCode)" -ForegroundColor Yellow
    } elseif ($process.ExitCode -eq 1603) {
        Write-Host "ERROR: Installation failed - Fatal error during installation" -ForegroundColor Red
        Write-Host "Exit Code: $($process.ExitCode)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Possible solutions:" -ForegroundColor Yellow
        Write-Host "1. Try running this script again" -ForegroundColor Yellow
        Write-Host "2. Temporarily disable antivirus" -ForegroundColor Yellow
        Write-Host "3. Check Windows Event Viewer for more details" -ForegroundColor Yellow
    } elseif ($process.ExitCode -eq 1618) {
        Write-Host "ERROR: Another installation is already in progress" -ForegroundColor Red
        Write-Host "Please wait for it to complete and try again" -ForegroundColor Yellow
    } elseif ($process.ExitCode -eq 5) {
        Write-Host "ERROR: Access denied - Insufficient permissions" -ForegroundColor Red
        Write-Host "Even though you're admin, Group Policy may be blocking installation" -ForegroundColor Yellow
    } else {
        Write-Host "WARNING: Installation completed with exit code: $($process.ExitCode)" -ForegroundColor Yellow
        Write-Host "This may indicate a partial installation" -ForegroundColor Yellow
    }

    Write-Host ""
} catch {
    Write-Host "ERROR: Failed to run Python installer" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit 1
}

# Clean up installer
Write-Host "Cleaning up installer file..." -ForegroundColor Yellow
Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
Write-Host "Cleanup complete: OK" -ForegroundColor Green
Write-Host ""

# Refresh environment variables
Write-Host "Refreshing environment variables..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
Write-Host "Environment refreshed: OK" -ForegroundColor Green
Write-Host ""

# Verify installation
Write-Host "Verifying Python installation..." -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 2

try {
    $pythonPath = Get-Command python -ErrorAction Stop
    $pythonVersionOutput = & python --version 2>&1

    Write-Host "============================================" -ForegroundColor Green
    Write-Host "VERIFICATION SUCCESSFUL!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "Python location: $($pythonPath.Source)" -ForegroundColor Cyan
    Write-Host "Python version: $pythonVersionOutput" -ForegroundColor Cyan
    Write-Host ""

    # Check pip
    $pipVersionOutput = & python -m pip --version 2>&1
    Write-Host "Pip version: $pipVersionOutput" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "============================================" -ForegroundColor Green
    Write-Host "Installation complete! You can now use Python." -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green

} catch {
    Write-Host "WARNING: Python command not found in PATH" -ForegroundColor Yellow
    Write-Host "You may need to:" -ForegroundColor Yellow
    Write-Host "1. Restart your terminal/VS Code" -ForegroundColor Yellow
    Write-Host "2. Restart your computer" -ForegroundColor Yellow
    Write-Host "3. Manually add Python to PATH" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Python is likely installed at:" -ForegroundColor Cyan
    Write-Host "  C:\Program Files\Python311\" -ForegroundColor Cyan
    Write-Host "  C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python311\" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
pause
