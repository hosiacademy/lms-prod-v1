# 💱 Currency Localization Deployment Guide

## Problem

The currency localization system is **implemented in code** but **NOT deployed** to the live website (https://www.hosiacademy.africa/).

### Current Status

| Component | Status | Details |
|-----------|--------|---------|
| Backend API | ✅ Deployed | Exchange rates endpoints working |
| Database | ✅ Deployed | 36 currencies loaded |
| Celery Beat | ✅ Deployed | Daily rate fetch scheduled |
| **Frontend** | ❌ **NOT Updated** | Static build from March 9 |

## Why It's Not Showing on the Website

The frontend is a **static Flutter web build** served from:
- Source: `/home/tk/lms-prod/frontend/`
- Built to: `/home/tk/lms-prod/frontend/build/web/`
- Deployed from: `/home/tk/lms-prod/frontend/prebuilt_web/`
- Container: `lms-prod-frontend-1`

**The prebuilt_web folder contains an OLD build** that doesn't have the currency localization properly initialized.

---

## Solution: Deploy the Frontend

### Option 1: Automated Script (Recommended)

```bash
cd /home/tk/lms-prod
./deploy-currency-localization.sh
```

This script will:
1. Clean Flutter build
2. Get dependencies
3. Build for web (release mode)
4. Update prebuilt_web folder
5. Rebuild Docker container
6. Restart frontend service
7. Verify deployment

**Duration:** 10-15 minutes

---

### Option 2: Manual Steps

```bash
# 1. Navigate to frontend
cd /home/tk/lms-prod/frontend

# 2. Clean and rebuild
flutter clean
flutter pub get
flutter build web --release --base-href="/"

# 3. Update prebuilt folder
rm -rf prebuilt_web/*
cp -r build/web/* prebuilt_web/

# 4. Rebuild and restart container
cd /home/tk/lms-prod
docker-compose build frontend
docker-compose up -d frontend

# 5. Verify
docker logs lms-prod-frontend-1 --tail 20
```

---

## After Deployment: Verify

### 1. Check Website
Visit: https://www.hosiacademy.africa/

Look for:
- Prices in ZAR (R), KES (KSh), NGN (₦), etc.
- NOT USD ($)

### 2. Test API Endpoints
```bash
# Exchange rates
curl http://localhost:7001/api/v1/payments/exchange-rates/

# Location detection
curl http://localhost:7001/api/v1/payments/detect-location/
```

### 3. Check Container
```bash
# Verify CurrencyService is in build
docker exec lms-prod-frontend-1 grep -o "CurrencyService" /usr/share/nginx/html/main.dart.js | wc -l
# Should return: 5+ (multiple occurrences)
```

---

## Expected Behavior After Deployment

### User in South Africa (IP: 197.x.x.x)
- Visits: https://www.hosiacademy.africa/
- Sees: Course prices in **ZAR (R)**
- Example: R 4,123 (instead of $250)

### User in Kenya (IP: 105.x.x.x)
- Visits: https://www.hosiacademy.africa/
- Sees: Course prices in **KES (KSh)**
- Example: KSh 32,290 (instead of $250)

### User in Nigeria (IP: 102.x.x.x)
- Visits: https://www.hosiacademy.africa/
- Sees: Course prices in **NGN (₦)**
- Example: ₦ 349,078 (instead of $250)

---

## Currency Conversion Examples

| USD Price | South Africa | Kenya | Nigeria | Zimbabwe |
|-----------|-------------|-------|---------|----------|
| $250 | R 4,123 | KSh 32,290 | ₦ 349,078 | $ 6,403 |
| $420 | R 6,926 | KSh 54,247 | ₦ 586,450 | $ 10,756 |

*Exchange rates as of 2026-03-10*

---

## Troubleshooting

### Frontend build fails
```bash
# Check Flutter installation
flutter doctor

# Fix any issues
flutter upgrade
```

### Container won't start
```bash
# Check logs
docker logs lms-prod-frontend-1

# Restart
docker-compose restart frontend
```

### Prices still showing in USD
1. Clear browser cache (Ctrl+Shift+Delete)
2. Hard refresh (Ctrl+F5)
3. Check if build actually updated:
   ```bash
   docker exec lms-prod-frontend-1 cat /usr/share/nginx/html/version.json
   ```

---

## Files Involved

### Backend (Already Deployed)
- `/backend/apps/payments/currency_localization.py`
- `/backend/apps/payments/exchange_rate_models.py`
- `/backend/apps/payments/tasks.py`
- `/backend/apps/payments/pricing_views.py`

### Frontend (Needs Deployment)
- `/frontend/lib/src/core/services/currency_service.dart`
- `/frontend/lib/src/core/constants/african_currencies.dart`
- `/frontend/lib/main.dart`

### Deployment
- `/frontend/prebuilt_web/` ← **This needs to be updated**
- `/deploy-currency-localization.sh` ← **Run this script**

---

## Summary

**The currency localization code is complete and working in the backend.** The only missing piece is **rebuilding and redeploying the frontend** to include the latest CurrencyService initialization.

**Run the deployment script** to push the changes to production:
```bash
./deploy-currency-localization.sh
```

**Expected result:** Users will see prices in their local African currency based on IP location.
