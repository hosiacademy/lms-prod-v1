@echo off
echo Testing Flutter compilation...
cd /d "C:\Users\HosiTech\lms-monorepo\frontend"

echo.
echo Running flutter analyze on the corporate module...
flutter analyze lib/src/presentation/blocs/course/corporate/

echo.
echo If you see import errors, check these common fixes:
echo 1. Make sure masterclass.dart exists in lib/src/data/models/
echo 2. Check if api_client.dart has getMasterclasses() method
echo 3. Verify the other widget/model files exist

pause
