#!/bin/bash
# Bash Script to Schedule Daily Image Sync with Cron
# Run this once to set up automated daily synchronization

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SYNC_SCRIPT="$SCRIPT_DIR/sync_course_images.dart"
WRAPPER_SCRIPT="$SCRIPT_DIR/run_sync.sh"
LOGS_DIR="$PROJECT_DIR/logs"

echo "═══════════════════════════════════════════════════════"
echo "🔄 Setting Up Daily Image Sync"
echo "═══════════════════════════════════════════════════════"
echo ""

# Check if Dart is installed
echo "🔍 Checking for Dart installation..."
if ! command -v dart &> /dev/null; then
    echo "   ⚠️  Dart not found in PATH"
    echo "   Dart comes with Flutter. Make sure Flutter is installed and in PATH"
    echo ""
    exit 1
fi

DART_PATH=$(which dart)
echo "   ✓ Found Dart at: $DART_PATH"
echo ""

# Create logs directory
echo "📁 Creating logs directory..."
mkdir -p "$LOGS_DIR"
echo "   ✓ Created: $LOGS_DIR"
echo ""

# Create wrapper script
echo "📝 Creating wrapper script..."
cat > "$WRAPPER_SCRIPT" << EOF
#!/bin/bash
# Wrapper script to run image sync with logging

cd "$PROJECT_DIR"
LOG_FILE="$LOGS_DIR/sync_\$(date +%Y-%m-%d).log"

echo "═══════════════════════════════════════════════════════" >> "\$LOG_FILE"
echo "Sync started at: \$(date)" >> "\$LOG_FILE"
echo "═══════════════════════════════════════════════════════" >> "\$LOG_FILE"

dart "$SYNC_SCRIPT" >> "\$LOG_FILE" 2>&1

echo "" >> "\$LOG_FILE"
echo "Sync finished at: \$(date)" >> "\$LOG_FILE"
echo "═══════════════════════════════════════════════════════" >> "\$LOG_FILE"
echo "" >> "\$LOG_FILE"
EOF

chmod +x "$WRAPPER_SCRIPT"
echo "   ✓ Created: $WRAPPER_SCRIPT"
echo ""

# Set up cron job
echo "⏰ Setting up cron job..."

# Check if crontab exists
if ! crontab -l &> /dev/null; then
    echo "   📝 Creating new crontab"
    echo "# AICerts Daily Image Sync" | crontab -
fi

# Remove existing entry if present
CRON_COMMENT="# AICerts Daily Image Sync"
CRON_JOB="0 3 * * * $WRAPPER_SCRIPT"

# Get current crontab and filter out old entry
crontab -l | grep -v "AICerts Daily Image Sync" | grep -v "$WRAPPER_SCRIPT" > /tmp/crontab.tmp

# Add new entry
echo "$CRON_COMMENT" >> /tmp/crontab.tmp
echo "$CRON_JOB" >> /tmp/crontab.tmp

# Install new crontab
crontab /tmp/crontab.tmp
rm /tmp/crontab.tmp

echo "   ✓ Cron job added"
echo ""

# Test run option
echo "═══════════════════════════════════════════════════════"
echo "✅ Setup Complete!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📋 Cron Job Details:"
echo "   • Schedule: Daily at 3:00 AM"
echo "   • Script: $SYNC_SCRIPT"
echo "   • Wrapper: $WRAPPER_SCRIPT"
echo "   • Logs: $LOGS_DIR"
echo ""
echo "🔧 Management Commands:"
echo "   • View cron jobs:  crontab -l"
echo "   • Edit cron jobs:  crontab -e"
echo "   • Remove this job: crontab -l | grep -v '$WRAPPER_SCRIPT' | crontab -"
echo "   • View logs:       tail -f $LOGS_DIR/sync_*.log"
echo ""

read -p "Would you like to run the sync now for testing? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Running sync now..."
    echo ""
    bash "$WRAPPER_SCRIPT"
    echo ""
    echo "✓ Sync complete. Check logs directory for output."
fi

echo ""
echo "Done! Images will sync automatically every day at 3:00 AM."
echo ""
