# 🔒 HTTPS Mixed Content Fix - DEPLOYMENT GUIDE

**Date:** March 13, 2026  
**Issue:** Mixed Content errors blocking API calls on HTTPS  
**Status:** ✅ **CODE FIXED - AWAITING BUILD**

---

## 📋 Summary

The HTTPS mixed content issue has been **fixed in code**, but requires a **Flutter web rebuild** to take effect.

### **What Was Fixed:**
✅ Updated `frontend/lib/src/core/config/environment.dart`  
✅ API calls will now use same origin (HTTPS) as frontend  
✅ Socket.IO connections will use WSS in production  

### **What's Needed:**
⏳ Rebuild Flutter web app with production settings  
⏳ Redeploy frontend container  

---

## 🔧 Deployment Options

### **Option 1: Build Locally (Recommended if Flutter Installed)**

```bash
# Navigate to frontend directory
cd /home/tk/lms-prod/frontend

# Build Flutter web app with production settings
flutter build web --release \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://www.hosiacademy.africa \
  --dart-define=SOCKET_URL=https://www.hosiacademy.africa

# Copy build output to prebuilt_web
cp -r build/web/* prebuilt_web/

# Rebuild Docker container
cd /home/tk/lms-prod
docker-compose build frontend
docker-compose up -d frontend
```

---

### **Option 2: Use Flutter Docker Image**

```bash
cd /home/tk/lms-prod

# Build using Flutter Docker container
docker run --rm \
  -v /home/tk/lms-prod/frontend:/app \
  -w /app \
  ghcr.io/cirrusci/flutter:3.24.0 \
  sh -c "flutter build web --release --dart-define=ENV=production --dart-define=API_BASE_URL=https://www.hosiacademy.africa"

# Copy build output
docker run --rm \
  -v /home/tk/lms-prod/frontend:/app \
  -w /app \
  alpine \
  sh -c "cp -r /app/build/web/* /app/prebuilt_web/"

# Rebuild and restart
docker-compose build frontend
docker-compose up -d frontend
```

**Note:** You may need to find the correct Flutter Docker image tag that matches your project's Flutter version.

---

### **Option 3: Manual Build on Development Machine**

If you have Flutter installed on your local machine:

```bash
# On your local development machine
cd /path/to/frontend

# Build for production
flutter build web --release \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://www.hosiacademy.africa

# Upload build files to server
scp -r build/web/* tk@154.66.211.3:/home/tk/lms-prod/frontend/prebuilt_web/

# Rebuild container on server
ssh tk@154.66.211.3
cd /home/tk/lms-prod
docker-compose build frontend
docker-compose up -d frontend
```

---

### **Option 4: Quick Fix (Update Nginx Config)**

As a **temporary workaround**, you can update the nginx configuration to force HTTPS redirects for API calls:

**File:** `frontend/nginx.conf`

Add this before the `/api/` location block:

```nginx
# Force HTTPS for API calls
location /api/ {
    # Add CORS headers
    add_header Access-Control-Allow-Origin https://www.hosiacademy.africa always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
    
    # Handle preflight
    if ($request_method = OPTIONS) {
        add_header Access-Control-Allow-Origin https://www.hosiacademy.africa always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
        add_header Content-Length 0;
        add_header Content-Type text/plain;
        return 204;
    }
    
    proxy_pass http://backend:8000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 120s;
    proxy_connect_timeout 10s;
}
```

Then rebuild:
```bash
cd /home/tk/lms-prod
docker-compose build frontend
docker-compose up -d frontend
```

**⚠️ Note:** This is a workaround. The proper fix is to rebuild the Flutter app.

---

## 🧪 Verification After Deploy

### **1. Check Browser Console**

Open `https://www.hosiacademy.africa/#/instructor/dashboard` and check console:

**Before Fix:**
```
❌ Mixed Content: The page at 'https://...' was loaded over HTTPS, 
   but requested an insecure XMLHttpRequest endpoint 'http://154.66.211.3:7001/api/...'
❌ CurrencyService: Backend detection failed: DioException [connection error]
```

**After Fix:**
```
✅ No mixed content errors
✅ CurrencyService: Initialized with ZAR (ZA)
✅ All API calls show (secure) in Network tab
```

### **2. Test API Calls**

In browser console (DevTools):
```javascript
// Test BBB sessions endpoint
fetch('/api/v1/bbb/sessions/my_sessions/', {
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN_HERE'
  }
})
.then(r => r.json())
.then(data => console.log('✅ Success:', data))
.catch(e => console.error('❌ Error:', e));
```

**Expected:** Valid JSON response with sessions

### **3. Check Network Tab**

In browser DevTools → Network:
- Filter by `/api/`
- All requests should show:
  - ✅ Protocol: `h2` or `http/1.1` (not `http` with warning)
  - ✅ No "Mixed Content" warnings
  - ✅ Status 200 OK

---

## 📊 Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Code Fix | ✅ Complete | `environment.dart` updated |
| Nginx Config | ✅ Correct | Already proxies `/api/` properly |
| Flutter Build | ⏳ Pending | Needs rebuild with production settings |
| Docker Image | ⏳ Pending | Needs rebuild after Flutter build |
| Deployment | ⏳ Pending | Container restart required |

---

## 🚨 Why Rebuild Is Necessary

The Flutter web app is **compiled ahead-of-time (AOT)**. The `environment.dart` values are baked into the compiled JavaScript (`main.dart.js`) at build time.

**File Structure:**
```
frontend/
├── lib/src/core/config/environment.dart  ← Source code (FIXED)
├── build/web/
│   ├── main.dart.js                       ← Compiled code (NEEDS REBUILD)
│   └── index.html
└── prebuilt_web/                          ← Copied to Docker image
    ├── main.dart.js                       ← This is what's currently running
    └── index.html
```

**Current Situation:**
- ✅ Source code fixed
- ❌ Compiled `main.dart.js` still has old HTTP URLs
- ❌ Docker container serves old compiled files

**Solution:**
1. Rebuild Flutter web app → generates new `main.dart.js`
2. Copy to `prebuilt_web/`
3. Rebuild Docker image
4. Restart container

---

## 📝 Alternative: Use Runtime Configuration

If rebuilding is not feasible, you can implement runtime configuration:

**Step 1:** Create `config.js` in `prebuilt_web/`:
```javascript
window.flutter_config = {
  'API_BASE_URL': 'https://www.hosiacademy.africa',
  'SOCKET_URL': 'https://www.hosiacademy.africa'
};
```

**Step 2:** Load before Flutter in `index.html`:
```html
<script src="config.js"></script>
<script src="main.dart.js"></script>
```

**Step 3:** Read config in Flutter:
```dart
// In environment.dart
@JS('flutter_config.API_BASE_URL')
external String? _getApiBaseUrlFromJS();

static String get apiBaseUrl {
  final jsUrl = _getApiBaseUrlFromJS();
  if (jsUrl != null && jsUrl.isNotEmpty) return jsUrl;
  // ... fallback logic
}
```

**⚠️ Note:** This requires code changes and is more complex than just rebuilding.

---

## 🎯 Recommended Next Steps

1. **Immediate:** Use Option 4 (nginx workaround) if urgent
2. **Short-term:** Rebuild Flutter app locally (Option 1 or 3)
3. **Long-term:** Set up CI/CD pipeline for automated builds

---

## 📞 Support

If you encounter issues:

1. **Build Fails:** Check Flutter version compatibility
2. **API Still HTTP:** Clear browser cache, force reload (Ctrl+Shift+R)
3. **CORS Errors:** Verify backend CORS settings
4. **Container Won't Start:** Check `docker logs lms-prod-frontend-1`

---

**Code Fix Applied:** March 13, 2026  
**Build Status:** ⏳ Pending  
**Estimated Time:** 10-15 minutes for full rebuild  
**Priority:** High (blocks all API functionality on HTTPS)
