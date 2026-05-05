param(
    [string]$ServerIP = "187.124.218.24",
    [string]$ServerUser = "root",
    [string]$RemotePath = "/opt/lms-prod"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STARTING UNIFIED DEPLOYMENT..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# STEP 0: Commit and push
Write-Host "STEP 0: Committing and pushing changes..." -ForegroundColor Yellow
Set-Location "C:\lms-prod"
git add .
git commit -m "Deployment: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git push origin master

# STEP 1: Build Flutter web
Write-Host "STEP 1: Building Flutter web..." -ForegroundColor Yellow
Set-Location "C:\lms-prod\frontend"
flutter build web --release --base-href="/"

# STEP 2: Create archive
Write-Host "STEP 2: Creating archive..." -ForegroundColor Yellow
if (Test-Path "C:\lms-prod\web_build.tar.gz") { Remove-Item "C:\lms-prod\web_build.tar.gz" -Force }
Set-Location "C:\lms-prod\frontend\build\web"
tar -czf "C:\lms-prod\web_build.tar.gz" .

# Verify archive was created
if (-Not (Test-Path "C:\lms-prod\web_build.tar.gz")) {
    Write-Host "ERROR: Archive not created. Aborting." -ForegroundColor Red
    exit 1
}
Write-Host "Archive created: $(Get-Item 'C:\lms-prod\web_build.tar.gz' | Select-Object -ExpandProperty Length) bytes" -ForegroundColor Green

# STEP 3: Upload to server
Write-Host "STEP 3: Uploading to server..." -ForegroundColor Yellow
scp -o StrictHostKeyChecking=no "C:\lms-prod\web_build.tar.gz" "root@187.124.218.24:/opt/lms-prod/"
Write-Host "Upload complete!" -ForegroundColor Green

# STEP 4: Deploy on server
Write-Host "STEP 4: Deploying on server..." -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no "root@187.124.218.24" @"
set -e
cd /opt/lms-prod
echo 'Pulling latest code...'
git pull origin master
echo 'Updating frontend files...'
rm -rf frontend/prebuilt_web
mkdir -p frontend/prebuilt_web
tar -xzf web_build.tar.gz -C frontend/prebuilt_web/
rm web_build.tar.gz
chmod -R 755 frontend/prebuilt_web/
echo 'Rebuilding and starting services...'
docker compose build --no-cache backend celery celery-2 celery-beat socketio flower
docker compose up -d
echo 'Running migrations...'
docker compose run --rm backend python manage.py migrate
echo 'Restarting nginx...'
docker restart lms_nginx 2>/dev/null || echo 'Nginx container not found'
docker system prune -f
echo 'Done!'
"@

# STEP 5: Cleanup
Write-Host "STEP 5: Cleanup..." -ForegroundColor Yellow
Remove-Item "C:\lms-prod\web_build.tar.gz" -Force -ErrorAction SilentlyContinue

Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Frontend: http://187.124.218.24:7000" -ForegroundColor Cyan
Write-Host "Backend:  http://187.124.218.24:7001" -ForegroundColor Cyan
