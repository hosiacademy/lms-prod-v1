#!/bin/bash
#
# Database Backup Script for LMS Platform
# Creates timestamped PostgreSQL backups with compression
#
# Usage:
#   ./scripts/backup_database.sh              # Local backup
#   ./scripts/backup_database.sh --s3         # Backup to S3
#   ./scripts/backup_database.sh --retention 7  # Keep 7 days
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_ROOT}/backups/database"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="lms_backup_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=${RETENTION_DAYS:-30}

# Colors for output
RED='\033[0:31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f "${PROJECT_ROOT}/backend/.env" ]; then
    export $(grep -v '^#' "${PROJECT_ROOT}/backend/.env" | xargs)
fi

# Default values if not set
DB_NAME=${DB_NAME:-hosiacademylms}
DB_USER=${DB_USER:-postgres}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}LMS Database Backup Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Database: ${DB_NAME}"
echo "Host: ${DB_HOST}:${DB_PORT}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Function to perform backup
perform_backup() {
    echo -e "${YELLOW}Creating database backup...${NC}"

    if [ -z "${DB_PASSWORD}" ]; then
        echo -e "${RED}Error: DB_PASSWORD not set in environment${NC}"
        exit 1
    fi

    # Create backup with pg_dump
    PGPASSWORD="${DB_PASSWORD}" pg_dump \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        --no-owner \
        --no-acl \
        --clean \
        --if-exists \
        | gzip > "${BACKUP_DIR}/${BACKUP_FILE}"

    if [ $? -eq 0 ]; then
        BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
        echo -e "${GREEN}✓ Backup created successfully${NC}"
        echo "  File: ${BACKUP_FILE}"
        echo "  Size: ${BACKUP_SIZE}"
        echo "  Location: ${BACKUP_DIR}/${BACKUP_FILE}"
    else
        echo -e "${RED}✗ Backup failed${NC}"
        exit 1
    fi
}

# Function to upload to S3
upload_to_s3() {
    if [ -z "${AWS_STORAGE_BUCKET_NAME}" ]; then
        echo -e "${YELLOW}Warning: AWS_STORAGE_BUCKET_NAME not set, skipping S3 upload${NC}"
        return
    fi

    echo -e "${YELLOW}Uploading to S3...${NC}"

    aws s3 cp \
        "${BACKUP_DIR}/${BACKUP_FILE}" \
        "s3://${AWS_STORAGE_BUCKET_NAME}/backups/database/${BACKUP_FILE}" \
        --storage-class STANDARD_IA

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Uploaded to S3${NC}"
        echo "  s3://${AWS_STORAGE_BUCKET_NAME}/backups/database/${BACKUP_FILE}"
    else
        echo -e "${RED}✗ S3 upload failed${NC}"
    fi
}

# Function to clean old backups
cleanup_old_backups() {
    echo -e "${YELLOW}Cleaning backups older than ${RETENTION_DAYS} days...${NC}"

    DELETED_COUNT=0
    while IFS= read -r old_backup; do
        rm -f "$old_backup"
        ((DELETED_COUNT++))
        echo "  Deleted: $(basename "$old_backup")"
    done < <(find "${BACKUP_DIR}" -name "lms_backup_*.sql.gz" -type f -mtime +${RETENTION_DAYS})

    if [ $DELETED_COUNT -eq 0 ]; then
        echo "  No old backups to delete"
    else
        echo -e "${GREEN}✓ Deleted ${DELETED_COUNT} old backup(s)${NC}"
    fi
}

# Function to verify backup
verify_backup() {
    echo -e "${YELLOW}Verifying backup integrity...${NC}"

    # Check if file exists and is not empty
    if [ ! -s "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
        echo -e "${RED}✗ Backup file is empty or doesn't exist${NC}"
        exit 1
    fi

    # Test gzip integrity
    if gzip -t "${BACKUP_DIR}/${BACKUP_FILE}" 2>/dev/null; then
        echo -e "${GREEN}✓ Backup file integrity verified${NC}"
    else
        echo -e "${RED}✗ Backup file is corrupted${NC}"
        exit 1
    fi

    # Test if it's valid SQL (just check the header)
    if zcat "${BACKUP_DIR}/${BACKUP_FILE}" | head -n 20 | grep -q "PostgreSQL database dump"; then
        echo -e "${GREEN}✓ Valid PostgreSQL dump format${NC}"
    else
        echo -e "${YELLOW}Warning: Unexpected dump format${NC}"
    fi
}

# Main execution
main() {
    # Parse arguments
    UPLOAD_S3=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --s3)
                UPLOAD_S3=true
                shift
                ;;
            --retention)
                RETENTION_DAYS="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: $0 [--s3] [--retention DAYS]"
                exit 1
                ;;
        esac
    done

    # Perform backup
    perform_backup

    # Verify backup
    verify_backup

    # Upload to S3 if requested
    if [ "$UPLOAD_S3" = true ]; then
        upload_to_s3
    fi

    # Cleanup old backups
    cleanup_old_backups

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Backup completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Run main function
main "$@"
