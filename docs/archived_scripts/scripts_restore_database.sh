#!/bin/bash
#
# Database Restore Script for LMS Platform
# Restores PostgreSQL database from backup
#
# Usage:
#   ./scripts/restore_database.sh backup_file.sql.gz
#   ./scripts/restore_database.sh --latest
#   ./scripts/restore_database.sh --from-s3 lms_backup_20260125_120000.sql.gz
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_ROOT}/backups/database"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load environment variables
if [ -f "${PROJECT_ROOT}/backend/.env" ]; then
    export $(grep -v '^#' "${PROJECT_ROOT}/backend/.env" | xargs)
fi

DB_NAME=${DB_NAME:-hosiacademylms}
DB_USER=${DB_USER:-postgres}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}LMS Database Restore Script${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Function to get latest backup
get_latest_backup() {
    LATEST=$(ls -t "${BACKUP_DIR}"/lms_backup_*.sql.gz 2>/dev/null | head -n 1)
    if [ -z "$LATEST" ]; then
        echo -e "${RED}Error: No backup files found in ${BACKUP_DIR}${NC}"
        exit 1
    fi
    echo "$LATEST"
}

# Function to download from S3
download_from_s3() {
    local s3_file=$1
    local local_file="${BACKUP_DIR}/${s3_file}"

    if [ -z "${AWS_STORAGE_BUCKET_NAME}" ]; then
        echo -e "${RED}Error: AWS_STORAGE_BUCKET_NAME not set${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Downloading from S3...${NC}"

    aws s3 cp \
        "s3://${AWS_STORAGE_BUCKET_NAME}/backups/database/${s3_file}" \
        "$local_file"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Downloaded from S3${NC}"
        echo "$local_file"
    else
        echo -e "${RED}✗ S3 download failed${NC}"
        exit 1
    fi
}

# Function to verify backup file
verify_backup_file() {
    local backup_file=$1

    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Error: Backup file not found: $backup_file${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Verifying backup file...${NC}"

    if ! gzip -t "$backup_file" 2>/dev/null; then
        echo -e "${RED}Error: Backup file is corrupted${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Backup file is valid${NC}"
}

# Function to create pre-restore backup
create_pre_restore_backup() {
    echo -e "${YELLOW}Creating pre-restore backup of current database...${NC}"

    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    PRE_RESTORE_BACKUP="${BACKUP_DIR}/pre_restore_${TIMESTAMP}.sql.gz"

    PGPASSWORD="${DB_PASSWORD}" pg_dump \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        --no-owner \
        --no-acl \
        | gzip > "$PRE_RESTORE_BACKUP"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Pre-restore backup created: $(basename $PRE_RESTORE_BACKUP)${NC}"
    else
        echo -e "${RED}✗ Pre-restore backup failed${NC}"
        echo -e "${YELLOW}Continuing without pre-restore backup...${NC}"
    fi
}

# Function to perform restore
perform_restore() {
    local backup_file=$1

    echo ""
    echo -e "${YELLOW}About to restore database from:${NC}"
    echo "  File: $(basename $backup_file)"
    echo "  Size: $(du -h $backup_file | cut -f1)"
    echo "  Database: ${DB_NAME}"
    echo "  Host: ${DB_HOST}:${DB_PORT}"
    echo ""
    echo -e "${RED}WARNING: This will DROP and recreate the database!${NC}"
    echo -e "${RED}All current data will be lost!${NC}"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Restore cancelled."
        exit 0
    fi

    echo ""
    echo -e "${YELLOW}Restoring database...${NC}"

    # Restore from backup
    zcat "$backup_file" | PGPASSWORD="${DB_PASSWORD}" psql \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        -v ON_ERROR_STOP=1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Database restored successfully${NC}"
    else
        echo -e "${RED}✗ Database restore failed${NC}"
        echo -e "${YELLOW}You may need to restore from the pre-restore backup${NC}"
        exit 1
    fi
}

# Function to run post-restore checks
post_restore_checks() {
    echo -e "${YELLOW}Running post-restore checks...${NC}"

    # Check if database is accessible
    if PGPASSWORD="${DB_PASSWORD}" psql \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        -c "SELECT 1" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Database is accessible${NC}"
    else
        echo -e "${RED}✗ Database is not accessible${NC}"
        exit 1
    fi

    # Check table count
    TABLE_COUNT=$(PGPASSWORD="${DB_PASSWORD}" psql \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'")

    echo "  Tables restored: ${TABLE_COUNT}"

    # Run Django checks
    if [ -f "${PROJECT_ROOT}/backend/manage.py" ]; then
        echo -e "${YELLOW}Running Django checks...${NC}"
        cd "${PROJECT_ROOT}/backend"
        python manage.py check --database default

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Django checks passed${NC}"
        else
            echo -e "${YELLOW}Warning: Django checks failed${NC}"
        fi
    fi
}

# Main execution
main() {
    BACKUP_FILE=""
    FROM_S3=false
    USE_LATEST=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --latest)
                USE_LATEST=true
                shift
                ;;
            --from-s3)
                FROM_S3=true
                BACKUP_FILE="$2"
                shift 2
                ;;
            *)
                BACKUP_FILE="$1"
                shift
                ;;
        esac
    done

    # Determine backup file
    if [ "$USE_LATEST" = true ]; then
        BACKUP_FILE=$(get_latest_backup)
        echo "Using latest backup: $(basename $BACKUP_FILE)"
    elif [ "$FROM_S3" = true ]; then
        BACKUP_FILE=$(download_from_s3 "$BACKUP_FILE")
    elif [ -z "$BACKUP_FILE" ]; then
        echo -e "${RED}Error: No backup file specified${NC}"
        echo "Usage: $0 <backup_file> | --latest | --from-s3 <s3_file>"
        exit 1
    fi

    # Verify backup file
    verify_backup_file "$BACKUP_FILE"

    # Create pre-restore backup
    create_pre_restore_backup

    # Perform restore
    perform_restore "$BACKUP_FILE"

    # Post-restore checks
    post_restore_checks

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Restore completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Run main function
main "$@"
