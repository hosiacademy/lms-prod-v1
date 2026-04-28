#!/bin/bash
#
# Setup Automated Database Backups with Cron
# Configures daily backups at 2 AM with S3 upload
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Setting up automated database backups...${NC}"

# Make scripts executable
chmod +x "${SCRIPT_DIR}/backup_database.sh"
chmod +x "${SCRIPT_DIR}/restore_database.sh"

# Create cron job
CRON_JOB="0 2 * * * ${SCRIPT_DIR}/backup_database.sh --s3 --retention 30 >> ${PROJECT_ROOT}/logs/backup.log 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "backup_database.sh"; then
    echo -e "${YELLOW}Cron job already exists${NC}"
else
    # Add to crontab
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo -e "${GREEN}✓ Cron job added${NC}"
fi

echo ""
echo "Backup schedule:"
echo "  Frequency: Daily at 2:00 AM"
echo "  Retention: 30 days"
echo "  S3 Upload: Enabled"
echo "  Log File: ${PROJECT_ROOT}/logs/backup.log"
echo ""
echo "To view scheduled backups:"
echo "  crontab -l | grep backup_database"
echo ""
echo "To remove scheduled backups:"
echo "  crontab -e  # Then delete the backup_database line"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
