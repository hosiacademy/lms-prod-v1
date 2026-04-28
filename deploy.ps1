# PowerShell Deployment Script for LMS
$SERVER = "entai"  # Using SSH config alias
$DEPLOY_PATH = "~/lms-prod"
$PUBLIC_IP = "154.66.211.3"

# Set error action to stop on first error
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   LMS PRODUCTION DEPLOYMENT STARTING     " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

try {
    # Dump database
    Write-Host "[1/9] Creating local database backup..." -ForegroundColor Yellow
    $env:PGPASSWORD = "MAZAtaka@45"
    & pg_dump -U postgres -h localhost -d hosiacademylms -f local_backup.sql
    if ($LASTEXITCODE -ne 0) { throw "Database dump failed" }
    $env:PGPASSWORD = $null

    # Test SSH
    Write-Host "[2/9] Testing SSH connection..." -ForegroundColor Yellow
    ssh $SERVER "echo 'SSH Connection Test: OK'"
    if ($LASTEXITCODE -ne 0) { throw "SSH connection failed" }

    # Create directory in user home
    Write-Host "[3/9] Preparing remote directory..." -ForegroundColor Yellow
    ssh $SERVER "mkdir -p $DEPLOY_PATH"

    # Transfer files
    Write-Host "[4/9] Transferring files (this may take a while)..." -ForegroundColor Yellow
    scp -r backend ${SERVER}:$DEPLOY_PATH/
    scp -r frontend ${SERVER}:$DEPLOY_PATH/
    scp docker-compose.yml ${SERVER}:$DEPLOY_PATH/
    scp docker-compose.prod.yml ${SERVER}:$DEPLOY_PATH/
    scp -r nginx ${SERVER}:$DEPLOY_PATH/
    scp local_backup.sql ${SERVER}:$DEPLOY_PATH/

    Write-Host "Files transferred successfully." -ForegroundColor Green

    # Setup environment
    Write-Host "[5/9] Setting up environment and injecting production variables..." -ForegroundColor Yellow
    ssh $SERVER "
        # Create SSL directory if not exists
        mkdir -p $DEPLOY_PATH/nginx/ssl
        
        # Generate self-signed certificate if it doesn't exist
        if [ ! -f $DEPLOY_PATH/nginx/ssl/fullchain.pem ]; then
            echo 'Generating self-signed SSL certificate...'
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout $DEPLOY_PATH/nginx/ssl/privkey.pem \
                -out $DEPLOY_PATH/nginx/ssl/fullchain.pem \
                -subj '/C=US/ST=State/L=City/O=LMS/CN=$PUBLIC_IP'
        fi

        cd $DEPLOY_PATH/backend
        if [ ! -f .env ]; then cp .env.example .env; fi
        
        # Inject production values using sed
        sed -i 's/^ENVIRONMENT=development/ENVIRONMENT=production/' .env
        sed -i 's/^DEBUG=True/DEBUG=False/' .env
        sed -i 's/^ALLOWED_HOSTS=.*/ALLOWED_HOSTS=localhost,127.0.0.1,$PUBLIC_IP/' .env
        sed -i 's|^BACKEND_BASE_URL=.*|BACKEND_BASE_URL=https://$PUBLIC_IP:7001|' .env
        sed -i 's|^FRONTEND_BASE_URL=.*|FRONTEND_BASE_URL=https://$PUBLIC_IP:7000|' .env
        sed -i 's|^CORS_ALLOWED_ORIGINS=.*|CORS_ALLOWED_ORIGINS=https://$PUBLIC_IP:7000|' .env
    "

    # Start services
    Write-Host "[6/9] Starting Docker services..." -ForegroundColor Yellow
    ssh $SERVER "cd $DEPLOY_PATH; docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build"

    Write-Host "Waiting for services to initialize (30s)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # Run migrations
    Write-Host "[7/9] Running database migrations..." -ForegroundColor Yellow
    ssh $SERVER "cd $DEPLOY_PATH; docker compose exec -T backend python manage.py migrate"

    # Collect static files
    Write-Host "[8/9] Collecting static files..." -ForegroundColor Yellow
    ssh $SERVER "cd $DEPLOY_PATH; docker compose exec -T backend python manage.py collectstatic --noinput"

    # Restore database
    Write-Host "[9/9] Restoring database content..." -ForegroundColor Yellow
    ssh $SERVER "cd $DEPLOY_PATH; cat local_backup.sql | docker compose exec -T db psql -U postgres -d hosiacademylms"

    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "   DEPLOYMENT SUCCESSFUL!                 " -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Site is now live at: https://$PUBLIC_IP:7000" -ForegroundColor White
    Write-Host "Nginx is proxying Frontend (7000) and Backend/Socket.IO (7001) over HTTPS." -ForegroundColor Gray
    
}
catch {
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "   DEPLOYMENT FAILED!                     " -ForegroundColor Red
    Write-Host "   Error: $_                               " -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    exit 1
}
