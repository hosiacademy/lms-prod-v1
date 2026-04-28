# PowerShell Script to Schedule Daily Image Sync
# Run this once to set up automated daily synchronization

$scriptPath = "$PSScriptRoot\sync_course_images.dart"
$projectPath = Split-Path -Parent $PSScriptRoot
$taskName = "AICerts_Daily_Image_Sync"

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔄 Setting Up Daily Image Sync" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  This script requires Administrator privileges" -ForegroundColor Yellow
    Write-Host "   Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

# Check if Dart is installed
Write-Host "🔍 Checking for Dart installation..."
$dartPath = (Get-Command dart -ErrorAction SilentlyContinue).Source

if (-not $dartPath) {
    Write-Host "   ⚠️  Dart not found in PATH" -ForegroundColor Yellow
    Write-Host "   Dart comes with Flutter. Make sure Flutter is installed and in PATH" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host "   ✓ Found Dart at: $dartPath" -ForegroundColor Green
Write-Host ""

# Create wrapper batch script
Write-Host "📝 Creating wrapper script..."
$wrapperPath = "$PSScriptRoot\run_sync.bat"
$wrapperContent = @"
@echo off
cd /d "$projectPath"
dart "$scriptPath" >> "logs\sync_$(Get-Date -Format 'yyyy-MM-dd').log" 2>&1
"@

Set-Content -Path $wrapperPath -Value $wrapperContent
Write-Host "   ✓ Created: $wrapperPath" -ForegroundColor Green
Write-Host ""

# Create logs directory
$logsDir = "$projectPath\logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
    Write-Host "📁 Created logs directory" -ForegroundColor Green
    Write-Host ""
}

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "🗑️  Removing existing scheduled task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "   ✓ Removed" -ForegroundColor Green
    Write-Host ""
}

# Create scheduled task
Write-Host "⏰ Creating scheduled task..."

$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$wrapperPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At "03:00AM"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U

Register-ScheduledTask -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Daily sync of AICerts course images for Flutter app" | Out-Null

Write-Host "   ✓ Task created: $taskName" -ForegroundColor Green
Write-Host ""

# Test run option
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Task Details:" -ForegroundColor Yellow
Write-Host "   • Name: $taskName"
Write-Host "   • Schedule: Daily at 3:00 AM"
Write-Host "   • Script: $scriptPath"
Write-Host "   • Logs: $logsDir"
Write-Host ""
Write-Host "🔧 Management Commands:" -ForegroundColor Yellow
Write-Host "   • View task: Get-ScheduledTask -TaskName '$taskName'"
Write-Host "   • Run now:   Start-ScheduledTask -TaskName '$taskName'"
Write-Host "   • Disable:   Disable-ScheduledTask -TaskName '$taskName'"
Write-Host "   • Remove:    Unregister-ScheduledTask -TaskName '$taskName'"
Write-Host ""

$runNow = Read-Host "Would you like to run the sync now for testing? (y/N)"
if ($runNow -eq 'y' -or $runNow -eq 'Y') {
    Write-Host ""
    Write-Host "🚀 Running sync now..." -ForegroundColor Cyan
    Write-Host ""
    Start-ScheduledTask -TaskName $taskName
    Start-Sleep -Seconds 2
    Write-Host "✓ Sync task started. Check logs directory for output." -ForegroundColor Green
}

Write-Host ""
Write-Host "Done! Images will sync automatically every day at 3:00 AM." -ForegroundColor Green
Write-Host ""
