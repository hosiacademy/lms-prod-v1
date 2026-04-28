@echo off
REM ============================================
REM RUN LMS FLUTTER APP (AFTER ERROR FIXES)
REM Double-click to test
REM ============================================

echo.
echo ============================================
echo LMS FLUTTER APP - TESTING AFTER FIXES
echo ============================================
echo.

cd /d %~dp0

echo Step 1: Cleaning Flutter build...
call flutter clean

echo.
echo Step 2: Getting dependencies...
call flutter pub get

echo.
echo Step 3: Running app on Chrome...
echo.
echo The app will open in your default browser.
echo Check the console (F12) for any remaining errors.
echo.

call flutter run -d chrome

pause
