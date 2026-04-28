@echo off
echo ==========================================
echo STARTING DJANGO SERVER AND TESTING IMAGES
echo ==========================================
echo.

echo Step 1: Testing that images exist...
if exist "media\profiles\defaults\sl1.jpeg" (
    echo [OK] Default images found
) else (
    echo [ERROR] Default images NOT found!
    echo Please ensure default profile images are placed in media\profiles\defaults\
    mkdir media\profiles\defaults 2>nul
    echo [INFO] Created media\profiles\defaults directory
    echo [INFO] Please copy your default profile images (sl*.jpeg, sm*.jpeg) to this directory
)

echo.
echo Step 2: Testing API response...
venv\Scripts\python.exe test_api_response.py

echo.
echo Step 3: Starting Django server on http://localhost:8000
echo.
echo ==================================================
echo AFTER SERVER STARTS, TEST THESE URLS IN BROWSER:
echo ==================================================
echo.
echo 1. API Test Endpoint (Shows 10 users with image URLs):
echo    http://localhost:8000/api/v1/profiles/test-images/
echo.
echo 2. Get All Profiles (Paginated list):
echo    http://localhost:8000/api/v1/profiles/?page=1^&limit=20
echo.
echo 3. Test Image Directly (Copy URL from API response):
echo    http://localhost:8000/media/profiles/defaults/sl1.jpeg
echo.
echo 4. Admin Panel (View users):
echo    http://localhost:8000/admin/
echo.
echo ==================================================
echo Press Ctrl+C to stop the server
echo ==================================================
echo.
timeout /t 3 /nobreak >nul

venv\Scripts\python.exe manage.py runserver
