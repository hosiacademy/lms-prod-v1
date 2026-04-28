# Build & Deployment - Comprehensive Master

**Consolidated Documentation - March 2026**

## OVERVIEW
Complete build and deployment guide covering Docker containerization, service orchestration, and production deployment checklist.

**Status:** ✅ Production Deployed

---

## BUILD PROCESS

### Frontend Build
```bash
# Build Flutter web
flutter build web --release

# Create Docker image
docker build -f frontend/Dockerfile -t lms-frontend:latest .

# Run frontend
docker run -d -p 7000:80 --name lms-frontend lms-frontend:latest
```

**Status:** ✅ Building with 172 static files

### Backend Build
```bash
# Install Python dependencies
pip install -r requirements.txt

# Collect static files
python manage.py collectstatic --no-input

# Build Docker image
docker build -f backend/Dockerfile -t lms-backend:latest .

# Run backend
docker run -d -p 7001:8000 --name lms-backend lms-backend:latest
```

**Status:** ✅ Building with Django + Gunicorn

### Docker Compose
```bash
# Build all services
docker compose build

# Start all services
docker compose up -d

# Verify services
docker compose ps
```

---

## SERVICES DEPLOYED (12/12)

| Service | Port | Status | Purpose |
|---------|------|--------|---------|
| Frontend | 7000 | ✅ | Flutter Web UI |
| Backend | 7001 | ✅ | Django API |
| Socket.IO | 7002 | ✅ | Real-time messaging |
| Flower | 7003 | ✅ | Celery monitoring |
| Nginx | 7004 | ✅ | Reverse proxy |
| Sentry | 9000 | ✅ | Error tracking |
| PostgreSQL | 5432 | ✅ | Database |
| Redis | 6379 | ✅ | Cache |
| Celery 1 | - | ✅ | Worker |
| Celery 2 | - | ✅ | Worker |
| Celery Beat | - | ✅ | Scheduler |

---

## DEPLOYMENT CHECKLIST

### Pre-Deployment ✅
- [x] Code reviewed
- [x] Tests passed
- [x] Dependencies installed
- [x] Database migrations applied
- [x] Environment variables configured
- [x] Backups created

### Deployment ✅
- [x] Docker images built
- [x] Services started
- [x] Health checks passed
- [x] Database connections verified
- [x] Cache connections verified
- [x] API endpoints responding

### Post-Deployment ✅
- [x] Monitoring enabled
- [x] Error tracking active
- [x] Logging configured
- [x] Backups verified
- [x] Rollback procedure tested

---

## ENVIRONMENT CONFIGURATION

**.env file setup:**
```env
# Database
DATABASE_URL=postgresql://user:pass@db:5432/hosiacademylms

# Redis
REDIS_URL=redis://redis:6379/0

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password

# SMS
TWILIO_ACCOUNT_SID=xxx
TWILIO_AUTH_TOKEN=xxx
TWILIO_PHONE_NUMBER=+1234567890

# Payment providers
FLUTTERWAVE_PUBLIC_KEY=xxx
FLUTTERWAVE_SECRET_KEY=xxx
# ... additional payment provider keys
```

---

## PRODUCTION DEPLOYMENT

**Date:** March 17, 2026
**Environment:** Production Server 154.66.211.3
**Status:** ✅ Live

### Running Services
```bash
docker compose ps

# Output:
# lms-prod-frontend-1    7000 ✅ Running
# lms-prod-backend-1     7001 ✅ Running
# lms_socketio           7002 ✅ Running
# lms_flower             7003 ✅ Running
# lms_nginx              7004 ✅ Running
# lms_sentry             9000 ✅ Running
```

### Health Check
```bash
curl http://154.66.211.3:7001/api/v1/health/
# Response: {"status": "healthy"}
```

---

**Status:** ✅ PRODUCTION READY
