@echo off
REM ============================================
REM HOSI ACADEMY LMS - DATABASE CLEANUP
REM Execute from Windows Command Prompt
REM ============================================

echo ============================================
echo HOSI ACADEMY LMS - DATABASE CLEANUP
echo ============================================
echo.

REM Database credentials
set DB_NAME=hosiacademylms
set DB_USER=postgres
set DB_HOST=localhost
set PGPASSWORD=MAZAtaka@45

REM Create backup directory
echo Step 1: Creating backup directory...
if not exist "C:\hosiacademylms_clean" mkdir "C:\hosiacademylms_clean"
if not exist "C:\hosiacademylms_clean\backups" mkdir "C:\hosiacademylms_clean\backups"
echo OK - Directory created: C:\hosiacademylms_clean\backups
echo.

REM Step 2: Create backup before cleanup
echo Step 2: Creating backup BEFORE cleanup...
set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_FILE=C:\hosiacademylms_clean\backups\hosiacademylms_BEFORE_%TIMESTAMP%.sql

echo Creating backup: %BACKUP_FILE%
pg_dump -U %DB_USER% -h %DB_HOST% -d %DB_NAME% > "%BACKUP_FILE%" 2>&1

if %errorlevel% equ 0 (
    echo OK - Backup created successfully
    dir "%BACKUP_FILE%"
) else (
    echo ERROR - Backup failed!
    pause
    exit /b 1
)
echo.

REM Step 3: Run cleanup SQL
echo Step 3: Running database cleanup...
echo Removing 6 dating location columns from users table...
echo.

psql -U %DB_USER% -h %DB_HOST% -d %DB_NAME% -f "%~dp0COMPLETE_DATABASE_CLEANUP.sql"

if %errorlevel% equ 0 (
    echo.
    echo OK - Database cleanup completed successfully
    echo.
) else (
    echo.
    echo ERROR - Cleanup failed!
    echo You can restore from: %BACKUP_FILE%
    pause
    exit /b 1
)

REM Step 4: Create clean backup after cleanup
echo Step 4: Creating CLEAN backup AFTER cleanup...
set CLEAN_BACKUP=C:\hosiacademylms_clean\backups\hosiacademylms_CLEAN_%TIMESTAMP%.sql

echo Creating clean backup: %CLEAN_BACKUP%
pg_dump -U %DB_USER% -h %DB_HOST% -d %DB_NAME% > "%CLEAN_BACKUP%" 2>&1

if %errorlevel% equ 0 (
    echo OK - Clean backup created successfully
    dir "%CLEAN_BACKUP%"
) else (
    echo WARNING - Clean backup failed (but cleanup was successful)
)
echo.

REM Step 5: Verification
echo Step 5: Running verification checks...
echo.

psql -U %DB_USER% -h %DB_HOST% -d %DB_NAME% -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name IN ('intro_video', 'latitude', 'longitude', 'based_city_id', 'based_country_id', 'based_state_id', 'origin_city_id', 'origin_country_id', 'origin_state_id');"

psql -U %DB_USER% -h %DB_HOST% -d %DB_NAME% -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name IN ('address', 'city', 'country', 'zip');"

psql -U %DB_USER% -h %DB_HOST% -d %DB_NAME% -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users';"

echo.
echo ============================================
echo CLEANUP COMPLETE!
echo ============================================
echo.
echo Backups location: C:\hosiacademylms_clean\backups\
echo.
echo   Before cleanup: %BACKUP_FILE%
echo   After cleanup:  %CLEAN_BACKUP%
echo.
echo To restore if needed:
echo   psql -U postgres -d hosiacademylms ^< "%BACKUP_FILE%"
echo.
echo ============================================
echo Your Hosi Academy LMS is now 100%% clean!
echo ============================================
echo.

pause
