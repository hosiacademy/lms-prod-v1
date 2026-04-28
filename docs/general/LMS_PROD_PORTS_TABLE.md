# 📊 LMS-PROD COMPLETE PORTS TABLE

**Last Updated:** March 13, 2026  
**Server IP:** 154.66.211.3  
**Status:** ✅ All Services Operational

---

## 🌐 Public-Facing Services

| Service | Host Port | Container Port | Protocol | Access URL | Purpose | Status |
|---------|-----------|----------------|----------|------------|---------|--------|
| **Frontend (Main)** | 7000 | 80 | TCP | http://154.66.211.3:7000 | Main web application UI (Flutter/Nginx) | ✅ Running |
| **Backend API** | 7001 | 8000 | TCP | http://154.66.211.3:7001/api/ | Django/Gunicorn API server | ✅ Running |
| **SocketIO** | 7002 | 8001 | TCP/WS | http://154.66.211.3:7002 | WebSocket real-time connections | ⚠️ Not Found |
| **Flower** | 7003 | 5555 | TCP | http://154.66.211.3:7003 | Celery task monitoring dashboard | ✅ Running |
| **Secondary Frontend** | 7004 | 80 | TCP | http://154.66.211.3:7004 | Secondary Nginx proxy instance | ✅ Running |
| **Secondary Frontend (HTTPS)** | 7005 | 443 | TCP | https://154.66.211.3:7005 | Secondary Nginx HTTPS | ✅ Running |
| **Sentry** | 9000 | 9000 | TCP | http://154.66.211.3:9000 | Error tracking & monitoring | ✅ Running |

---

## 🔒 Internal Database Ports (Container-to-Container Only)

| Service | Container Port | Protocol | Container Name | Purpose | Status |
|---------|----------------|----------|----------------|---------|--------|
| **PostgreSQL** | 5432 | TCP | lms_db | Main database (hosiacademylms) | ✅ Healthy |
| **Redis** | 6379 | TCP | lms_redis | Cache & message broker | ✅ Healthy |

**Note:** These ports are NOT exposed to the host. They are only accessible within the Docker network.

---

## 🎯 Important API Endpoints (Port 7001)

| Endpoint | Method | Purpose | Test Command |
|----------|--------|---------|--------------|
| `/api/v1/auth/login/` | POST | User authentication | `curl -X POST http://localhost:7001/api/v1/auth/login/` |
| `/api/v1/courses/masterclasses/` | GET | Masterclasses listing | `curl http://localhost:7001/api/v1/courses/masterclasses/` |
| `/api/v1/bbb/sessions/my_sessions/` | GET | Instructor BBB sessions | `curl -H "Authorization: Bearer <TOKEN>" http://localhost:7001/api/v1/bbb/sessions/my_sessions/` |
| `/api/v1/payments/exchange-rates/` | GET | Currency exchange rates | `curl http://localhost:7001/api/v1/payments/exchange-rates/` |
| `/api/v1/payments/detect-location/` | GET | IP-based location detection | `curl http://localhost:7001/api/v1/payments/detect-location/` |
| `/api/v1/payments/providers/` | GET | Payment providers by country | `curl "http://localhost:7001/api/v1/payments/providers/?country=ZA&amount=1000&currency=ZAR"` |
| `/api/v1/student-portal/dashboard/` | GET | Student dashboard data | `curl -H "Authorization: Bearer <TOKEN>" http://localhost:7001/api/v1/student-portal/dashboard/` |
| `/api/v1/facilitators/profiles/dashboard/` | GET | Instructor dashboard data | `curl -H "Authorization: Bearer <TOKEN>" http://localhost:7001/api/v1/facilitators/profiles/dashboard/` |
| `/api/v1/learnerships/` | GET | Learnership programmes | `curl http://localhost:7001/api/v1/learnerships/` |
| `/api/v1/aicerts/courses/` | GET | AICERTS courses | `curl http://localhost:7001/api/v1/aicerts/courses/` |

---

## 🐳 Container Names & Current Status

| Container Name | Host Port | Container Port | Status | Health | Purpose |
|----------------|-----------|----------------|--------|--------|---------|
| `lms-prod-frontend-1` | 7000 | 80 | ✅ Up 54 min | - | Main web server (Flutter/Nginx) |
| `lms-prod-backend-1` | 7001 | 8000 | ✅ Up 51 min | - | Django API server |
| `lms_socketio` | - | 8001 | ❌ Not Found | - | WebSocket server (MISSING) |
| `lms_flower` | 7003 | 5555 | ✅ Up 51 min | - | Celery monitoring dashboard |
| `lms_nginx` | 7004, 7005 | 80, 443 | ✅ Up 51 min | - | Secondary Nginx proxy |
| `lms_sentry` | 9000 | 9000 | ✅ Up 25 hrs | - | Error tracking (Sentry) |
| `lms_db` | (internal) | 5432 | ✅ Up 17 hrs | ✅ Healthy | PostgreSQL database |
| `lms_redis` | (internal) | 6379 | ✅ Up 25 hrs | ✅ Healthy | Redis cache |
| `lms_celery_beat` | (internal) | 8000 | ✅ Up 51 min | - | Celery task scheduler |
| `lms-prod-celery-1` | (internal) | 8000 | ✅ Up 23 sec | - | Celery worker #1 |
| `lms-prod-celery-2` | (internal) | 8000 | ✅ Up 1 min | - | Celery worker #2 |

---

## ⚠️ Service Alerts

### **SocketIO Service Missing**
The SocketIO container (`lms_socketio`) is not running. This service handles:
- Real-time chat messaging
- Live notifications
- WebSocket connections for live sessions

**Action Required:** Start the SocketIO service if real-time features are needed.

---

## 🔧 Quick Verification Commands

### **List All Containers**
```bash
# List all running containers with ports
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | grep lms
```

### **Test Frontend**
```bash
# Test main frontend (Port 7000)
curl -I http://localhost:7000

# Expected: HTTP/1.1 200 OK
```

### **Test Backend API**
```bash
# Test backend API health (Port 7001)
curl -s "http://localhost:7001/api/v1/payments/providers/?country=ZA&amount=1000&currency=ZAR" | python3 -m json.tool

# Expected: JSON response with payment providers
```

### **Test BBB Sessions Endpoint**
```bash
# Test instructor BBB sessions (requires auth token)
curl -s -H "Authorization: Bearer <JWT_TOKEN>" \
  http://localhost:7001/api/v1/bbb/sessions/my_sessions/ | python3 -m json.tool

# Expected: {"upcoming": [...], "live": [...], "past": [...]}
```

### **Check Backend Logs**
```bash
# View last 50 log lines
docker logs lms-prod-backend-1 --tail 50

# Follow logs in real-time
docker logs -f lms-prod-backend-1
```

### **Check Database Health**
```bash
# Check PostgreSQL container health
docker inspect lms_db --format='{{.State.Health.Status}}'

# Expected: healthy
```

### **Check Redis Health**
```bash
# Check Redis container health
docker inspect lms_redis --format='{{.State.Health.Status}}'

# Expected: healthy
```

### **Test Flower Dashboard**
```bash
# Test Flower monitoring (Port 7003)
curl -I http://localhost:7003

# Expected: HTTP/1.1 200 OK
```

---

## 🌐 Access URLs Summary

```
╔════════════════════════════════════════════════════════════════════╗
║                    LMS-PROD SERVICE ACCESS URLs                     ║
╠════════════════════════════════════════════════════════════════════╣
║ 🌐 Frontend:        http://154.66.211.3:7000                       ║
║ 🔧 Backend API:     http://154.66.211.3:7001/api/v1/               ║
║ 🔌 SocketIO:        http://154.66.211.3:7002  ⚠️ NOT RUNNING       ║
║ 📊 Flower:          http://154.66.211.3:7003                       ║
║ 📡 Secondary Web:   http://154.66.211.3:7004                       ║
║ 🔒 Secondary HTTPS: https://154.66.211.3:7005                      ║
║ 🚨 Sentry:          http://154.66.211.3:9000                       ║
╚════════════════════════════════════════════════════════════════════╝
```

---

## 🔐 Security Notes

### **Exposed Ports**
- **7000-7005**: Public-facing web services
- **9000**: Sentry error tracking (consider restricting access)

### **Internal Only (Not Exposed)**
- **5432**: PostgreSQL database
- **6379**: Redis cache

### **Recommendations**
1. Consider adding firewall rules to restrict access to port 9000 (Sentry)
2. Use HTTPS for all public-facing services in production
3. Regularly rotate database credentials
4. Monitor Sentry for application errors

---

## 📊 Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      INTERNET                                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   HOST SERVER (154.66.211.3)                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Docker Network (bridge)                  │   │
│  │                                                       │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │   │
│  │  │   Frontend   │  │    Backend   │  │  SocketIO  │  │   │
│  │  │   :7000      │  │    :7001     │  │   (DOWN)   │  │   │
│  │  └──────────────┘  └──────────────┘  └────────────┘  │   │
│  │                                                       │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │   │
│  │  │    Flower    │  │    Nginx     │  │   Sentry   │  │   │
│  │  │   :7003      │  │  :7004/:7005 │  │   :9000    │  │   │
│  │  └──────────────┘  └──────────────┘  └────────────┘  │   │
│  │                                                       │   │
│  │  ┌──────────────┐  ┌──────────────┐                  │   │
│  │  │  PostgreSQL  │  │    Redis     │                  │   │
│  │  │  :5432 (int) │  │  :6379 (int) │                  │   │
│  │  └──────────────┘  └──────────────┘                  │   │
│  │                                                       │   │
│  │  ┌──────────────┐  ┌──────────────┐                  │   │
│  │  │   Celery 1   │  │   Celery 2   │                  │   │
│  │  │  :8000 (int) │  │  :8000 (int) │                  │   │
│  │  └──────────────┘  └──────────────┘                  │   │
│  │                                                       │   │
│  │  ┌──────────────┐                                     │   │
│  │  │ Celery Beat  │                                     │   │
│  │  │  :8000 (int) │                                     │   │
│  │  └──────────────┘                                     │   │
│  └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Service Management Commands

### **Start All Services**
```bash
cd /home/tk/lms-prod
docker-compose up -d
```

### **Restart Specific Service**
```bash
docker-compose restart backend
docker-compose restart frontend
```

### **Stop All Services**
```bash
docker-compose down
```

### **View Service Logs**
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

### **Check Service Health**
```bash
docker-compose ps
```

---

## 📈 Performance Monitoring

### **Resource Usage**
```bash
# View container resource usage
docker stats --no-stream

# Continuous monitoring
docker stats
```

### **Database Queries**
```bash
# Check PostgreSQL connections
docker exec lms_db psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"
```

### **Redis Cache**
```bash
# Check Redis memory usage
docker exec lms_redis redis-cli INFO memory
```

---

## 🎯 BBB Integration Status

| Component | Status | Endpoint | Notes |
|-----------|--------|----------|-------|
| BBB Server | ✅ Active | http://bbb.hosiacademy.africa/bigbluebutton/api/ | External server |
| Backend API | ✅ Fixed | `/api/v1/bbb/sessions/my_sessions/` | 9 upcoming sessions |
| Frontend UI | ⏳ Testing | Tab 6: BBB | Ready for verification |
| Session Data | ✅ Ready | Database | 9 sessions scheduled |

---

**Documentation Generated:** March 13, 2026  
**Next Review:** March 20, 2026  
**Responsible:** DevOps Team
