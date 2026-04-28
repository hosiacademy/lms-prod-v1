@echo off
REM Quick test script for Windows to verify profile pictures are working
REM Run this: TEST_IMAGES_NOW.bat

echo ==========================================
echo PROFILE PICTURES TEST - Hosi Academy LMS
echo ==========================================
echo.

echo Step 1: Checking media directory...
if exist "media\profiles\defaults" (
    echo [OK] Media directory exists
    echo   Files found:
    dir /b media\profiles\defaults | more
) else (
    echo [ERROR] Media directory NOT found: media\profiles\defaults\
    echo.
    echo CREATING directory...
    mkdir media\profiles\defaults
    echo [INFO] Created media\profiles\defaults directory
    echo [INFO] Please copy your default profile images to this directory:
    echo        - Female defaults: sl1.jpeg, sl2.jpeg, etc.
    echo        - Male defaults: sm1.jpeg, sm2.jpeg, etc.
)

echo.
echo Step 2: Testing database users...
python manage.py test_profile_pictures

echo.
echo Step 3: Starting Django server...
echo   Server will start at http://localhost:8000
echo.
echo After server starts, test these URLs in your browser:
echo.
echo   1. Test API endpoint:
echo      http://localhost:8000/api/v1/profiles/test-images/
echo.
echo   2. Get all profiles:
echo      http://localhost:8000/api/v1/profiles/?page=1^&limit=20
echo.
echo   3. Test image directly:
echo      http://localhost:8000/media/profiles/defaults/sl1.jpeg
echo.
echo Press Ctrl+C to stop the server
echo.
echo ==========================================
echo Starting server in 3 seconds...
timeout /t 3 /nobreak >nul

python manage.py runserver
