# Uninstall Python 3.14 PowerShell Script
# Run as Administrator

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Python 3.14 Uninstall Script" -ForegroundColor Cyan
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

# Find Python 3.14 using Windows Registry
Write-Host "Searching for Python 3.14 installations..." -ForegroundColor Yellow
Write-Host ""

$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$pythonApps = @()

foreach ($key in $uninstallKeys) {
    try {
        $apps = Get-ItemProperty $key -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -like "*Python 3.14*" -or
            $_.DisplayName -like "*Python 3.1*" -and $_.DisplayName -like "*3.14*"
        }
        $pythonApps += $apps
    } catch {
        # Ignore errors
    }
}

if ($pythonApps.Count -eq 0) {
    Write-Host "No Python 3.14 installation found in registry" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "Found $($pythonApps.Count) Python 3.14 installation(s):" -ForegroundColor Green
    Write-Host ""

    foreach ($app in $pythonApps) {
        Write-Host "  Name: $($app.DisplayName)" -ForegroundColor Cyan
        Write-Host "  Version: $($app.DisplayVersion)" -ForegroundColor Gray
        Write-Host "  Location: $($app.InstallLocation)" -ForegroundColor Gray

        if ($app.QuietUninstallString) {
            Write-Host "  Uninstalling..." -ForegroundColor Yellow
            try {
                Start-Process cmd.exe -ArgumentList "/c $($app.QuietUninstallString)" -Wait -NoNewWindow
                Write-Host "  ✓ Uninstalled successfully" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Failed to uninstall: $($_.Exception.Message)" -ForegroundColor Red
            }
        } elseif ($app.UninstallString) {
            Write-Host "  Uninstalling..." -ForegroundColor Yellow
            try {
                $uninstallCmd = $app.UninstallString -replace '"', ''
                if ($uninstallCmd -like "*.exe*") {
                    Start-Process -FilePath $uninstallCmd -ArgumentList "/quiet", "/uninstall" -Wait -NoNewWindow
                    Write-Host "  ✓ Uninstalled successfully" -ForegroundColor Green
                }
            } catch {
                Write-Host "  ✗ Failed to uninstall: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-Host ""
    }
}

# Also check and remove common installation directories
$pythonDirs = @(
    "C:\Users\Administrator\AppData\Local\Programs\Python\Python314",
    "C:\Program Files\Python314",
    "C:\Python314"
)

Write-Host "Checking for Python 3.14 directories..." -ForegroundColor Yellow
Write-Host ""

foreach ($dir in $pythonDirs) {
    if (Test-Path $dir) {
        Write-Host "Found directory: $dir" -ForegroundColor Cyan
        try {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
            Write-Host "✓ Removed directory" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed to remove: $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# Clean up PATH environment variable
Write-Host "Cleaning up PATH environment variable..." -ForegroundColor Yellow

$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

$cleanedMachinePath = ($machinePath -split ';' | Where-Object { $_ -notlike "*Python314*" -and $_ -notlike "*Python\3.14*" }) -join ';'
$cleanedUserPath = ($userPath -split ';' | Where-Object { $_ -notlike "*Python314*" -and $_ -notlike "*Python\3.14*" }) -join ';'

if ($machinePath -ne $cleanedMachinePath) {
    [Environment]::SetEnvironmentVariable("Path", $cleanedMachinePath, "Machine")
    Write-Host "✓ Cleaned Machine PATH" -ForegroundColor Green
} else {
    Write-Host "  Machine PATH already clean" -ForegroundColor Gray
}

if ($userPath -ne $cleanedUserPath) {
    [Environment]::SetEnvironmentVariable("Path", $cleanedUserPath, "User")
    Write-Host "✓ Cleaned User PATH" -ForegroundColor Green
} else {
    Write-Host "  User PATH already clean" -ForegroundColor Gray
}

Write-Host ""

Write-Host "============================================" -ForegroundColor Green
Write-Host "Python 3.14 Uninstall Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: install-python311.ps1" -ForegroundColor Cyan
Write-Host "2. Restart VS Code or your terminal" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
pause
