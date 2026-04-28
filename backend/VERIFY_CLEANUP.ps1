# ============================================
# VERIFY DATABASE CLEANUP
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "DATABASE CLEANUP VERIFICATION" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$env:PGPASSWORD = "MAZAtaka@45"
$DB_NAME = "hosiacademylms"
$DB_USER = "postgres"
$DB_HOST = "localhost"

Write-Host "Checking cleanup results..." -ForegroundColor Yellow
Write-Host ""

# Check dating columns (should be 0)
Write-Host "1. Dating columns removed:" -ForegroundColor White
$DatingColumns = & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name IN ('intro_video', 'latitude', 'longitude', 'based_city_id', 'based_country_id', 'based_state_id', 'origin_city_id', 'origin_country_id', 'origin_state_id');"
$DatingColumns = $DatingColumns.Trim()

if ($DatingColumns -eq "0") {
    Write-Host "   [OK] Dating columns: $DatingColumns (all removed)" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Dating columns: $DatingColumns (should be 0)" -ForegroundColor Red
}

Write-Host ""

# Check total columns (should be 84)
Write-Host "2. Total user columns:" -ForegroundColor White
$TotalColumns = & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users';"
$TotalColumns = $TotalColumns.Trim()

if ($TotalColumns -eq "84") {
    Write-Host "   [OK] Total columns: $TotalColumns (expected: 84)" -ForegroundColor Green
} else {
    Write-Host "   [INFO] Total columns: $TotalColumns (expected: 84)" -ForegroundColor Yellow
}

Write-Host ""

# Check LMS location fields (should be 4)
Write-Host "3. LMS location fields preserved:" -ForegroundColor White
$LMSFields = & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name IN ('address', 'city', 'country', 'zip');"
$LMSFields = $LMSFields.Trim()

if ($LMSFields -eq "4") {
    Write-Host "   [OK] LMS location fields: $LMSFields (address, city, country, zip)" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] LMS location fields: $LMSFields (should be 4)" -ForegroundColor Red
}

Write-Host ""

# Check table count
Write-Host "4. Total database tables:" -ForegroundColor White
$TableCount = & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -t -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public';"
$TableCount = $TableCount.Trim()
Write-Host "   [INFO] Tables: $TableCount" -ForegroundColor Cyan

Write-Host ""

# Check user_profile_images table (should not exist)
Write-Host "5. Profile images table:" -ForegroundColor White
$ProfileImagesTable = & psql -U $DB_USER -h $DB_HOST -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'user_profile_images';"
$ProfileImagesTable = $ProfileImagesTable.Trim()

if ($ProfileImagesTable -eq "0") {
    Write-Host "   [OK] user_profile_images table: DROPPED (does not exist)" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] user_profile_images table: EXISTS (should be dropped)" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "VERIFICATION COMPLETE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Summary
if ($DatingColumns -eq "0" -and $TotalColumns -eq "84" -and $LMSFields -eq "4" -and $ProfileImagesTable -eq "0") {
    Write-Host "[SUCCESS] Database cleanup verified!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your Hosi Academy LMS is 100% clean:" -ForegroundColor White
    Write-Host "  - 0 dating columns remaining" -ForegroundColor Gray
    Write-Host "  - 84 user columns (down from 90)" -ForegroundColor Gray
    Write-Host "  - 4 LMS location fields preserved" -ForegroundColor Gray
    Write-Host "  - Profile images table removed" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "[WARNING] Some checks did not pass" -ForegroundColor Yellow
    Write-Host "Review the results above" -ForegroundColor Gray
    Write-Host ""
}

# Clean up
Remove-Item env:PGPASSWORD

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
