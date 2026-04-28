# 📊 LMS-PROD PORTS - QUICK REFERENCE

**Server:** 154.66.211.3 | **Updated:** March 13, 2026

---

## 🎯 Quick Access

| Service | Port | URL | Status |
|---------|------|-----|--------|
| 🌐 **Frontend** | 7000 | http://154.66.211.3:7000 | ✅ |
| 🔧 **Backend API** | 7001 | http://154.66.211.3:7001/api/ | ✅ |
| 📊 **Flower** | 7003 | http://154.66.211.3:7003 | ✅ |
| 📡 **Secondary** | 7004 | http://154.66.211.3:7004 | ✅ |
| 🚨 **Sentry** | 9000 | http://154.66.211.3:9000 | ✅ |

---

## 🔍 Health Check (One-Liner)

```bash
echo "Frontend: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:7000)" && \
echo "Backend:  $(curl -s -o /dev/null -w '%{http_code}' http://localhost:7001/api/)" && \
echo "Flower:   $(curl -s -o /dev/null -w '%{http_code}' http://localhost:7003)" && \
echo "Sentry:   $(curl -s -o /dev/null -w '%{http_code}' http://localhost:9000)"
```

**Expected Output:**
```
Frontend: 200
Backend:  404 (API root returns 404 - normal)
Flower:   200
Sentry:   200
```

---

## 🐳 Container Status (One-Liner)

```bash
docker ps --format "table {{.Names}}\t{{.Status}}" | grep lms
```

---

## 🔑 Key API Endpoints

```bash
# BBB Sessions (Instructor Dashboard)
curl -H "Authorization: Bearer <TOKEN>" \
  http://localhost:7001/api/v1/bbb/sessions/my_sessions/

# Payment Providers
curl "http://localhost:7001/api/v1/payments/providers/?country=ZA&amount=1000"

# Masterclasses
curl http://localhost:7001/api/v1/courses/masterclasses/

# Instructor Dashboard
curl -H "Authorization: Bearer <TOKEN>" \
  http://localhost:7001/api/v1/facilitators/profiles/dashboard/
```

---

## 📦 Internal Services

| Service | Port | Container | Status |
|---------|------|-----------|--------|
| PostgreSQL | 5432 | lms_db | ✅ Healthy |
| Redis | 6379 | lms_redis | ✅ Healthy |
| Celery Worker 1 | 8000 | lms-prod-celery-1 | ✅ Running |
| Celery Worker 2 | 8000 | lms-prod-celery-2 | ✅ Running |
| Celery Beat | 8000 | lms_celery_beat | ✅ Running |

---

## ⚠️ Missing Services

| Service | Port | Status | Action |
|---------|------|--------|--------|
| SocketIO | 7002 | ❌ Not Running | Start if real-time features needed |

---

## 🚀 Common Commands

```bash
# Restart backend
docker-compose restart backend

# View backend logs
docker logs -f lms-prod-backend-1 --tail 50

# Check database
docker exec lms_db psql -U postgres -c "\dt"

# Check Redis
docker exec lms_redis redis-cli ping

# Restart all
docker-compose down && docker-compose up -d
```

---

## 📊 Port Summary

```
Public Ports:  7000, 7001, 7003, 7004, 7005, 9000
Internal:      5432 (DB), 6379 (Redis)
Missing:       7002 (SocketIO)
```

---

**Full Documentation:** See `LMS_PROD_PORTS_TABLE.md`
