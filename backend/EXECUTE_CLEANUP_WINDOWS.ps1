# ============================================
# HOSI ACADEMY LMS - DATABASE CLEANUP
# Execute from Windows PowerShell
# Run as: .\EXECUTE_CLEANUP_WINDOWS.ps1
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "HOSI ACADEMY LMS - DATABASE CLEANUP" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Database credentials
$env:PGPASSWORD = "MAZAtaka@45"
$DB_NAME = "hosiacademylms"
$DB_USER = "postgres"
$DB_HOST = "localhost"

# Create backup directory
Write-Host "Step 1: Creating backup directory..." -ForegroundColor Yellow
$BackupDir = "C:\hosiacademylms_clean\backups"
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "[OK] Directory created: $BackupDir" -ForegroundColor Green
} else {
    Write-Host "[OK] Directory exists: $BackupDir" -ForegroundColor Green
}
Write-Host ""

# Generate timestamp
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Step 2: Create backup BEFORE cleanup
Write-Host "Step 2: Creating backup BEFORE cleanup..." -ForegroundColor Yellow
$BackupFile = "$BackupDir\hosiacademylms_BEFORE_$Timestamp.sql"
Write-Host "Creating backup: $BackupFile" -ForegroundColor Gray

try {
    $output = & pg_dump -U $DB_USER -h $DB_HOST -d $DB_NAME 2>&1 | Out-File -FilePath $BackupFile -Encoding UTF8
    $FileSize = (Get-Item $BackupFile).Length / 1MB
    Write-Host "[OK] Backup created: $([math]::Round($FileSize, 2)) MB" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Backup failed: $_" -ForegroundColor Red
    pause
    exit 1
}
Write-Host ""

# Step 3: Run cleanup SQL
Write-Host "Step 3: Running database cleanup..." -ForegroundColor Yellow
Write-Host "Removing 6 dating location columns from users table..." -ForegroundColor Gray
Write-Host ""

$CleanupScript = Join-Path $PSScriptRoot "COMPLETE_DATABASE_CLEANUP.sql"

try {
    & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -f $CleanupScript
    Write-Host ""
    Write-Host "[OK] Database cleanup completed successfully" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host ""
    Write-Host "[ERROR] Cleanup failed: $_" -ForegroundColor Red
    Write-Host "You can restore from: $BackupFile" -ForegroundColor Yellow
    pause
    exit 1
}

# Step 4: Create CLEAN backup AFTER cleanup
Write-Host "Step 4: Creating CLEAN backup AFTER cleanup..." -ForegroundColor Yellow
$CleanBackupFile = "$BackupDir\hosiacademylms_CLEAN_$Timestamp.sql"
Write-Host "Creating clean backup: $CleanBackupFile" -ForegroundColor Gray

try {
    & pg_dump -U $DB_USER -h $DB_HOST -d $DB_NAME 2>&1 | Out-File -FilePath $CleanBackupFile -Encoding UTF8
    $CleanFileSize = (Get-Item $CleanBackupFile).Length / 1MB
    Write-Host "[OK] Clean backup created: $([math]::Round($CleanFileSize, 2)) MB" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Clean backup failed (but cleanup was successful)" -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Verification
Write-Host "Step 5: Running verification checks..." -ForegroundColor Yellow
Write-Host ""

# Check dating columns (should be 0)
$DatingColumns = & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name IN ('intro_video', 'latitude', 'longitude', 'based_city_id', 'based_country_id', 'based_state_id', 'origin_city_id', 'origin_country_id', 'origin_state_id');"
$DatingColumns = $DatingColumns.Trim()

if ($DatingColumns -eq "0") {
    Write-Host "[OK] Dating columns: 0 (all removed)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Dating columns: $DatingColumns (should be 0)" -ForegroundColor Red
}

# Check LMS location columns (should be 4)
$LMSColumns = & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name IN ('address', 'city', 'country', 'zip');"
$LMSColumns = $LMSColumns.Trim()

if ($LMSColumns -eq "4") {
    Write-Host "[OK] LMS location fields: 4 (all preserved)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] LMS location fields: $LMSColumns (should be 4)" -ForegroundColor Red
}

# Check total columns
$TotalColumns = & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users';"
$TotalColumns = $TotalColumns.Trim()
Write-Host "[INFO] Users table columns: $TotalColumns (expected: 84)" -ForegroundColor Cyan

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backups location: $BackupDir" -ForegroundColor White
Write-Host ""
Write-Host "  Before cleanup:" -ForegroundColor Gray
Write-Host "    $BackupFile" -ForegroundColor White
Write-Host ""
Write-Host "  After cleanup:" -ForegroundColor Gray
Write-Host "    $CleanBackupFile" -ForegroundColor White
Write-Host ""
Write-Host "To restore if needed:" -ForegroundColor Yellow
Write-Host "  psql -U postgres -d hosiacademylms < `"$BackupFile`"" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Your Hosi Academy LMS is now 100% clean!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Clean up password
Remove-Item env:PGPASSWORD

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
