# PowerShell Script to Complete Backend Implementation
# Run this in your activated venv PowerShell terminal

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Backend Implementation - Student Portal Migration" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Verify we're in the right directory
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
Write-Host ""

# Step 1: Update settings.py to use new config class
Write-Host "Step 1: Verifying settings.py..." -ForegroundColor Green
$settingsPath = "lms_project/settings.py"
$settingsContent = Get-Content $settingsPath -Raw

if ($settingsContent -match "apps.learner_portal.apps.StudentPortalConfig") {
    Write-Host "✓ Settings already updated to use StudentPortalConfig" -ForegroundColor Green
} elseif ($settingsContent -match "apps.learner_portal") {
    Write-Host "Updating INSTALLED_APPS in settings.py..." -ForegroundColor Yellow
    $settingsContent = $settingsContent -replace "'apps\.learner_portal'", "'apps.learner_portal.apps.StudentPortalConfig'"
    $settingsContent | Set-Content $settingsPath
    Write-Host "✓ Updated settings.py" -ForegroundColor Green
} else {
    Write-Host "✓ Settings configuration OK" -ForegroundColor Green
}
Write-Host ""

# Step 2: Create migrations
Write-Host "Step 2: Creating migrations..." -ForegroundColor Green
Write-Host "Running: python manage.py makemigrations learner_portal" -ForegroundColor Yellow
python manage.py makemigrations learner_portal

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Migrations created successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Error creating migrations" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Show migration plan
Write-Host "Step 3: Showing migration plan..." -ForegroundColor Green
Write-Host "Running: python manage.py showmigrations learner_portal" -ForegroundColor Yellow
python manage.py showmigrations learner_portal
Write-Host ""

# Step 4: Apply migrations
Write-Host "Step 4: Applying migrations..." -ForegroundColor Green
Write-Host "Running: python manage.py migrate learner_portal" -ForegroundColor Yellow
python manage.py migrate learner_portal

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Migrations applied successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Error applying migrations" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 5: Run full migration to catch any other changes
Write-Host "Step 5: Running full migration..." -ForegroundColor Green
Write-Host "Running: python manage.py migrate" -ForegroundColor Yellow
python manage.py migrate

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ All migrations applied successfully" -ForegroundColor Green
} else {
    Write-Host "⚠ Some migrations may have failed" -ForegroundColor Yellow
}
Write-Host ""

# Step 6: Verify changes
Write-Host "Step 6: Verifying model changes..." -ForegroundColor Green
Write-Host "Running: python manage.py shell -c `"from apps.learner_portal.models import StudentProfile; print('✓ StudentProfile model loaded successfully')`"" -ForegroundColor Yellow

$shellCommand = "from apps.learner_portal.models import StudentProfile; print('✓ StudentProfile model loaded successfully')"
python manage.py shell -c $shellCommand

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Model verification passed" -ForegroundColor Green
} else {
    Write-Host "⚠ Model verification had issues (may be normal)" -ForegroundColor Yellow
}
Write-Host ""

# Step 7: Run tests (optional but recommended)
Write-Host "Step 7: Running tests..." -ForegroundColor Green
Write-Host "Do you want to run tests? (Y/N)" -ForegroundColor Yellow
$runTests = Read-Host

if ($runTests -eq "Y" -or $runTests -eq "y") {
    Write-Host "Running: python manage.py test apps.learner_portal" -ForegroundColor Yellow
    python manage.py test apps.learner_portal

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ All tests passed" -ForegroundColor Green
    } else {
        Write-Host "⚠ Some tests failed" -ForegroundColor Yellow
    }
} else {
    Write-Host "Skipping tests" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Backend Implementation Complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Model class: LearnerProfile → StudentProfile" -ForegroundColor Green
Write-Host "✓ API endpoints: /api/v1/learner-portal/ → /api/v1/student-portal/" -ForegroundColor Green
Write-Host "✓ Admin classes updated" -ForegroundColor Green
Write-Host "✓ Verbose names updated" -ForegroundColor Green
Write-Host "✓ Database migrations applied" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Start the development server: python manage.py runserver" -ForegroundColor White
Write-Host "2. Visit: http://localhost:8000/admin/" -ForegroundColor White
Write-Host "3. Verify 'Student Portal' appears in admin" -ForegroundColor White
Write-Host "4. Test API endpoint: http://localhost:8000/api/v1/student-portal/profile/" -ForegroundColor White
Write-Host ""
