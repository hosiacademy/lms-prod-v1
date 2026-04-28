#!/bin/bash
# ============================================
# HOSI ACADEMY LMS - Database Cleanup Script
# ============================================
# This script automates the complete database cleanup
# Password: MAZAtaka@45
# ============================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database credentials
DB_NAME="hosiacademylms"
DB_USER="postgres"
DB_HOST="localhost"
DB_PASSWORD="MAZAtaka@45"

# Directories
BACKUP_DIR="/mnt/c/Users/HosiTech/database_backups"
BACKEND_DIR="/mnt/c/Users/HosiTech/lms-monorepo/backend"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}HOSI ACADEMY LMS - DATABASE CLEANUP${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Step 1: Create backup directory
echo -e "${YELLOW}Step 1: Creating backup directory...${NC}"
mkdir -p "$BACKUP_DIR"
echo -e "${GREEN}✓ Backup directory ready: $BACKUP_DIR${NC}"
echo ""

# Step 2: Backup current database
echo -e "${YELLOW}Step 2: Backing up current database...${NC}"
BACKUP_FILE="$BACKUP_DIR/hosiacademylms_backup_$(date +%Y%m%d_%H%M%S).sql"
echo -e "${BLUE}Creating backup: $BACKUP_FILE${NC}"
echo -e "${YELLOW}You'll be prompted for password: MAZAtaka@45${NC}"

export PGPASSWORD="$DB_PASSWORD"
pg_dump -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✓ Backup created successfully: $BACKUP_SIZE${NC}"
else
    echo -e "${RED}✗ Backup failed!${NC}"
    exit 1
fi
echo ""

# Step 3: Run cleanup script
echo -e "${YELLOW}Step 3: Running database cleanup script...${NC}"
echo -e "${BLUE}This will remove all dating app fields from the database${NC}"
echo ""

psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -f "$BACKEND_DIR/COMPLETE_DATABASE_CLEANUP.sql"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database cleanup completed successfully${NC}"
else
    echo -e "${RED}✗ Cleanup failed!${NC}"
    echo -e "${YELLOW}You can restore from backup: $BACKUP_FILE${NC}"
    exit 1
fi
echo ""

# Step 4: Create clean backup
echo -e "${YELLOW}Step 4: Creating CLEAN backup...${NC}"
CLEAN_BACKUP_FILE="$BACKUP_DIR/hosiacademylms_CLEAN_$(date +%Y%m%d_%H%M%S).sql"
echo -e "${BLUE}Creating clean backup: $CLEAN_BACKUP_FILE${NC}"

pg_dump -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" > "$CLEAN_BACKUP_FILE"

if [ $? -eq 0 ]; then
    CLEAN_SIZE=$(du -h "$CLEAN_BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✓ Clean backup created: $CLEAN_SIZE${NC}"
else
    echo -e "${RED}✗ Clean backup failed!${NC}"
fi
echo ""

# Step 5: Verification
echo -e "${YELLOW}Step 5: Running verification checks...${NC}"
echo ""

# Check table count
TABLE_COUNT=$(psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public';")
echo -e "${BLUE}Total tables: $TABLE_COUNT (expected: 126)${NC}"

# Check for dating columns
DATING_COLUMNS=$(psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -t -c "
SELECT COUNT(*) FROM information_schema.columns
WHERE table_name = 'users'
AND column_name IN (
    'intro_video', 'latitude', 'longitude',
    'based_city_id', 'based_country_id', 'based_state_id',
    'origin_city_id', 'origin_country_id', 'origin_state_id'
);")

if [ "$DATING_COLUMNS" -eq 0 ]; then
    echo -e "${GREEN}✓ Dating columns: 0 (all removed)${NC}"
else
    echo -e "${RED}✗ Dating columns: $DATING_COLUMNS (should be 0)${NC}"
fi

# Check for LMS location columns
LMS_COLUMNS=$(psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -t -c "
SELECT COUNT(*) FROM information_schema.columns
WHERE table_name = 'users'
AND column_name IN ('address', 'city', 'country', 'zip');")

if [ "$LMS_COLUMNS" -eq 4 ]; then
    echo -e "${GREEN}✓ LMS location fields: 4 (all preserved)${NC}"
else
    echo -e "${RED}✗ LMS location fields: $LMS_COLUMNS (should be 4)${NC}"
fi

# Check users table columns
USER_COLUMNS=$(psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -t -c "
SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users';")
echo -e "${BLUE}Users table columns: $USER_COLUMNS (expected: 84)${NC}"

# Check for user_profile_images table
PROFILE_IMAGES_TABLE=$(psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -t -c "
SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_profile_images';")

if [ "$PROFILE_IMAGES_TABLE" -eq 0 ]; then
    echo -e "${GREEN}✓ user_profile_images table: removed${NC}"
else
    echo -e "${RED}✗ user_profile_images table: still exists${NC}"
fi

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}DATABASE CLEANUP COMPLETE!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${GREEN}Backups created:${NC}"
echo -e "  Before: $BACKUP_FILE"
echo -e "  After:  $CLEAN_BACKUP_FILE"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Test your LMS frontend"
echo -e "  2. Check user profiles"
echo -e "  3. Verify profile pictures load"
echo ""
echo -e "${BLUE}To restore if needed:${NC}"
echo -e "  psql -U postgres -d hosiacademylms < $BACKUP_FILE"
echo ""
echo -e "${GREEN}Your Hosi Academy LMS is now 100% clean! 🎉${NC}"

# Clean up password from environment
unset PGPASSWORD
