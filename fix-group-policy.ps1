# Fix Group Policy to Allow Python Installation
# Run as Administrator

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Group Policy Fix for Python Installation" -ForegroundColor Cyan
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

# Registry paths for Windows Installer policies
$machinePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
$userPath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer"

Write-Host "Checking Windows Installer policies..." -ForegroundColor Yellow
Write-Host ""

# Check Machine-level policy
Write-Host "Machine-level policies:" -ForegroundColor Cyan
if (Test-Path $machinePath) {
    $machineProps = Get-ItemProperty -Path $machinePath -ErrorAction SilentlyContinue
    if ($machineProps) {
        $machineProps | Format-List

        # Remove DisableMSI if it exists
        if ($machineProps.PSObject.Properties.Name -contains "DisableMSI") {
            Write-Host "  Removing DisableMSI restriction..." -ForegroundColor Yellow
            Remove-ItemProperty -Path $machinePath -Name "DisableMSI" -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Removed DisableMSI" -ForegroundColor Green
        }

        # Set to allow all installations
        Set-ItemProperty -Path $machinePath -Name "DisableMSI" -Value 0 -Force
        Write-Host "  ✓ Set DisableMSI = 0 (Allow all)" -ForegroundColor Green
    } else {
        Write-Host "  No restrictive policies found" -ForegroundColor Gray
    }
} else {
    Write-Host "  No policy key exists (OK)" -ForegroundColor Gray
}
Write-Host ""

# Check User-level policy
Write-Host "User-level policies:" -ForegroundColor Cyan
if (Test-Path $userPath) {
    $userProps = Get-ItemProperty -Path $userPath -ErrorAction SilentlyContinue
    if ($userProps) {
        $userProps | Format-List

        # Remove DisableMSI if it exists
        if ($userProps.PSObject.Properties.Name -contains "DisableMSI") {
            Write-Host "  Removing DisableMSI restriction..." -ForegroundColor Yellow
            Remove-ItemProperty -Path $userPath -Name "DisableMSI" -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Removed DisableMSI" -ForegroundColor Green
        }

        # Set to allow all installations
        Set-ItemProperty -Path $userPath -Name "DisableMSI" -Value 0 -Force
        Write-Host "  ✓ Set DisableMSI = 0 (Allow all)" -ForegroundColor Green
    } else {
        Write-Host "  No restrictive policies found" -ForegroundColor Gray
    }
} else {
    Write-Host "  No policy key exists (OK)" -ForegroundColor Gray
}
Write-Host ""

# Also check for DisableUserInstalls
Write-Host "Checking DisableUserInstalls policy..." -ForegroundColor Yellow
if (Test-Path $machinePath) {
    $disableUserInstalls = Get-ItemProperty -Path $machinePath -Name "DisableUserInstalls" -ErrorAction SilentlyContinue
    if ($disableUserInstalls) {
        Write-Host "  Found DisableUserInstalls = $($disableUserInstalls.DisableUserInstalls)" -ForegroundColor Cyan
        Write-Host "  Setting to 0 (Allow user installs)..." -ForegroundColor Yellow
        Set-ItemProperty -Path $machinePath -Name "DisableUserInstalls" -Value 0 -Force
        Write-Host "  ✓ User installs now allowed" -ForegroundColor Green
    } else {
        Write-Host "  DisableUserInstalls not set (OK)" -ForegroundColor Gray
    }
}
Write-Host ""

# Refresh Group Policy
Write-Host "Refreshing Group Policy..." -ForegroundColor Yellow
try {
    gpupdate /force | Out-Null
    Write-Host "✓ Group Policy refreshed" -ForegroundColor Green
} catch {
    Write-Host "⚠ Could not refresh Group Policy automatically" -ForegroundColor Yellow
    Write-Host "  Run 'gpupdate /force' manually" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "============================================" -ForegroundColor Green
Write-Host "Group Policy Fix Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: install-python311.ps1" -ForegroundColor Cyan
Write-Host "2. If still blocked, restart your computer and try again" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
pause
