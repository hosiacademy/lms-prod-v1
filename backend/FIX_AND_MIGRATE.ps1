# Fix Environment and Run Migrations
# Run this script to fix all issues and create migrations

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Fixing Environment & Running Migrations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clear Python cache
Write-Host "[1/5] Clearing Python cache..." -ForegroundColor Yellow
Get-ChildItem -Path . -Recurse -Filter "__pycache__" -Directory | Remove-Item -Recurse -Force
Get-ChildItem -Path . -Recurse -Filter "*.pyc" -File | Remove-Item -Force
Write-Host "  ✓ Cache cleared" -ForegroundColor Green
Write-Host ""

# Step 2: Verify .env credentials
Write-Host "[2/5] Verifying .env credentials..." -ForegroundColor Yellow
$dbUser = Select-String -Path ".env" -Pattern "^DB_USER=" | Select-Object -First 1
$aicertsId = Select-String -Path ".env" -Pattern "^AICERTS_PARTNER_ID=" | Select-Object -First 1

Write-Host "  Current DB_USER: $dbUser" -ForegroundColor Cyan
Write-Host "  Current AICERTS_PARTNER_ID: $aicertsId" -ForegroundColor Cyan

if ($dbUser -match "DB_USER=postgres") {
    Write-Host "  ✓ Database user correct" -ForegroundColor Green
} else {
    Write-Host "  ✗ Database user incorrect!" -ForegroundColor Red
    Write-Host "  Manually edit .env and set: DB_USER=postgres" -ForegroundColor Yellow
    exit 1
}

if ($aicertsId -match "262") {
    Write-Host "  ✓ AICERTs Partner ID correct" -ForegroundColor Green
} else {
    Write-Host "  ✗ AICERTs Partner ID missing!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Test database connection
Write-Host "[3/5] Testing database connection..." -ForegroundColor Yellow
python test_db_connection.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ Database connection failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check PostgreSQL:" -ForegroundColor Yellow
    Write-Host "  1. Is PostgreSQL running?" -ForegroundColor White
    Write-Host "  2. Is password correct in .env?" -ForegroundColor White
    Write-Host "  3. Does database 'hosiacademylms' exist?" -ForegroundColor White
    exit 1
}
Write-Host ""

# Step 4: Create migrations
Write-Host "[4/5] Creating migrations..." -ForegroundColor Yellow

Write-Host "  → users app..." -ForegroundColor Cyan
python manage.py makemigrations users

Write-Host "  → aicerts_integration app..." -ForegroundColor Cyan
python manage.py makemigrations aicerts_integration

Write-Host "  → reviews app..." -ForegroundColor Cyan
python manage.py makemigrations reviews

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Migrations created" -ForegroundColor Green
} else {
    Write-Host "  ✗ Migration creation failed!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 5: Apply migrations
Write-Host "[5/5] Applying migrations..." -ForegroundColor Yellow
python manage.py migrate

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Migrations applied successfully" -ForegroundColor Green
} else {
    Write-Host "  ✗ Migration failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " ✓ Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Start server: python manage.py runserver" -ForegroundColor White
Write-Host "  2. Visit admin: http://localhost:8000/admin/" -ForegroundColor White
Write-Host "  3. Check AICERTs Integration sections" -ForegroundColor White
Write-Host ""
