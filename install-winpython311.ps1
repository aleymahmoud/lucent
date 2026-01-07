# WinPython 3.11 Portable Installation Script
# No admin rights needed - runs without installation

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "WinPython 3.11 Portable Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This is a PORTABLE version - no installation required!" -ForegroundColor Green
Write-Host ""

# WinPython download URL (portable version)
$winPythonUrl = "https://github.com/winpython/winpython/releases/download/7.0.20240331final/Winpython64-3.11.8.1.exe"
$downloadPath = "C:\Lucent\WinPython311.exe"
$extractPath = "C:\Lucent\WinPython311"

Write-Host "Downloading WinPython 3.11..." -ForegroundColor Yellow
Write-Host "URL: $winPythonUrl" -ForegroundColor Gray
Write-Host ""

try {
    Invoke-WebRequest -Uri $winPythonUrl -OutFile $downloadPath -UseBasicParsing
    Write-Host "Download complete!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: Failed to download" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit 1
}

Write-Host "Extracting WinPython (this may take a few minutes)..." -ForegroundColor Yellow

try {
    # Run the self-extracting archive
    Start-Process -FilePath $downloadPath -ArgumentList "-o`"$extractPath`" -y" -Wait
    Write-Host "Extraction complete!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: Failed to extract" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit 1
}

# Find python.exe in extracted folder
$pythonExe = Get-ChildItem -Path $extractPath -Filter "python.exe" -Recurse | Select-Object -First 1

if ($pythonExe) {
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "WinPython Installation Complete!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Python location: $($pythonExe.FullName)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To use this Python, run:" -ForegroundColor Yellow
    Write-Host "  cd C:\Lucent\backend" -ForegroundColor Cyan
    Write-Host "  $($pythonExe.FullName) -m pip install -r requirements-core.txt" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "ERROR: Could not find python.exe" -ForegroundColor Red
}

Write-Host "Press any key to exit..." -ForegroundColor Gray
pause
