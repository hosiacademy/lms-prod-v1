# ============================================
# RESTORE DATABASE FROM BACKUP
# Execute from Windows PowerShell
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "DATABASE BACKUP CHECK & RESTORE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if backup directory exists
$BackupDir = "C:\hosiacademylms_clean\backups"

if (-not (Test-Path $BackupDir)) {
    Write-Host "[ERROR] Backup directory not found: $BackupDir" -ForegroundColor Red
    Write-Host "Please run the cleanup script first: .\EXECUTE_CLEANUP_WINDOWS.ps1" -ForegroundColor Yellow
    pause
    exit 1
}

# List all backups
Write-Host "Available backups in: $BackupDir" -ForegroundColor Cyan
Write-Host ""

$Backups = Get-ChildItem -Path $BackupDir -Filter "*.sql" | Sort-Object LastWriteTime -Descending

if ($Backups.Count -eq 0) {
    Write-Host "[ERROR] No backup files found!" -ForegroundColor Red
    pause
    exit 1
}

# Display backups
$Index = 1
foreach ($Backup in $Backups) {
    $Size = [math]::Round($Backup.Length / 1MB, 2)
    $Time = $Backup.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$Index] $($Backup.Name)" -ForegroundColor White
    Write-Host "    Size: $Size MB" -ForegroundColor Gray
    Write-Host "    Date: $Time" -ForegroundColor Gray
    Write-Host ""
    $Index++
}

# Ask user which backup to restore
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Select backup to restore (or 0 to cancel):" -ForegroundColor Yellow
$Selection = Read-Host "Enter number"

if ($Selection -eq "0") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    pause
    exit 0
}

$SelectedIndex = [int]$Selection - 1
if ($SelectedIndex -lt 0 -or $SelectedIndex -ge $Backups.Count) {
    Write-Host "[ERROR] Invalid selection!" -ForegroundColor Red
    pause
    exit 1
}

$SelectedBackup = $Backups[$SelectedIndex]
$BackupFile = $SelectedBackup.FullName

Write-Host ""
Write-Host "Selected: $($SelectedBackup.Name)" -ForegroundColor Green
Write-Host ""
Write-Host "WARNING: This will OVERWRITE the current database!" -ForegroundColor Red
Write-Host "Database: hosiacademylms" -ForegroundColor Yellow
Write-Host ""
$Confirm = Read-Host "Type 'YES' to continue"

if ($Confirm -ne "YES") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    pause
    exit 0
}

# Database credentials
$env:PGPASSWORD = "MAZAtaka@45"
$DB_NAME = "hosiacademylms"
$DB_USER = "postgres"
$DB_HOST = "localhost"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "RESTORING DATABASE..." -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Drop and recreate database
Write-Host "Step 1: Dropping existing database..." -ForegroundColor Yellow
try {
    & psql -U $DB_USER -h $DB_HOST -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
    Write-Host "[OK] Database dropped" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to drop database: $_" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "Step 2: Creating new database..." -ForegroundColor Yellow
try {
    & psql -U $DB_USER -h $DB_HOST -d postgres -c "CREATE DATABASE $DB_NAME;"
    Write-Host "[OK] Database created" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to create database: $_" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "Step 3: Restoring from backup..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray

try {
    & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -f $BackupFile 2>&1 | Out-Null
    Write-Host "[OK] Database restored successfully" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to restore: $_" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "Step 4: Verification..." -ForegroundColor Yellow

# Check table count
$TableCount = & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -t -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public';"
$TableCount = $TableCount.Trim()
Write-Host "[INFO] Total tables: $TableCount" -ForegroundColor Cyan

# Check users table columns
$UserColumns = & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users';"
$UserColumns = $UserColumns.Trim()
Write-Host "[INFO] Users table columns: $UserColumns" -ForegroundColor Cyan

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "RESTORE COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Restored from: $($SelectedBackup.Name)" -ForegroundColor White
Write-Host "Database: hosiacademylms" -ForegroundColor White
Write-Host "Tables: $TableCount" -ForegroundColor White
Write-Host "User columns: $UserColumns" -ForegroundColor White
Write-Host ""

# Clean up password
Remove-Item env:PGPASSWORD

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
