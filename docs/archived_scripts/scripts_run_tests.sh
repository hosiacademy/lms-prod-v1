#!/bin/bash

# ==================== LMS TESTING SCRIPT ====================
# This script sets up the test environment and runs all tests
# with coverage reporting.
#
# Usage:
#   ./scripts/run_tests.sh              # Run all tests
#   ./scripts/run_tests.sh unit         # Run unit tests only
#   ./scripts/run_tests.sh integration  # Run integration tests only
#   ./scripts/run_tests.sh api          # Run API tests only
#   ./scripts/run_tests.sh --coverage   # Run with coverage report
#
# Requirements:
#   - Python 3.10+
#   - PostgreSQL running (for integration tests)
#   - Redis running (for integration tests)

set -e  # Exit on error

cd "$(dirname "$0")/.." || exit 1
BACKEND_DIR="backend"

echo "========================================="
echo "LMS Testing Script"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running in Docker or local
if [ -f "/.dockerenv" ]; then
    echo "📦 Running in Docker container"
    PYTHON_CMD="python"
    PYTEST_CMD="pytest"
else
    echo "💻 Running on local machine"

    # Check for virtual environment
    if [ ! -d "$BACKEND_DIR/venv" ]; then
        echo -e "${YELLOW}⚠️  No virtual environment found. Creating one...${NC}"
        cd "$BACKEND_DIR"
        python3 -m venv venv
        source venv/bin/activate

        echo "📦 Installing dependencies..."
        pip install --upgrade pip
        pip install -r requirements.txt
        pip install -r requirements-dev.txt
        cd ..
    else
        echo "✅ Virtual environment found"
        cd "$BACKEND_DIR"
        source venv/bin/activate
        cd ..
    fi

    PYTHON_CMD="$BACKEND_DIR/venv/bin/python"
    PYTEST_CMD="$BACKEND_DIR/venv/bin/pytest"
fi

# Change to backend directory
cd "$BACKEND_DIR" || exit 1

echo ""
echo "========================================="
echo "Environment Check"
echo "========================================="

# Check Python version
echo -n "Python version: "
$PYTHON_CMD --version

# Check if pytest is installed
if ! command -v $PYTEST_CMD &> /dev/null; then
    echo -e "${RED}❌ pytest not found. Installing test dependencies...${NC}"
    pip install -r requirements-dev.txt
fi

echo "✅ pytest found: $($PYTEST_CMD --version)"

# Check PostgreSQL connection (for integration tests)
echo -n "PostgreSQL: "
if $PYTHON_CMD -c "import psycopg2; psycopg2.connect('postgresql://lms_user:HosiAcad3my!P0stgr3s#2026\$Secure@localhost:5432/hosiacademylms')" 2>/dev/null; then
    echo -e "${GREEN}✅ Connected${NC}"
    HAS_POSTGRES=true
else
    echo -e "${YELLOW}⚠️  Not available (integration tests will be skipped)${NC}"
    HAS_POSTGRES=false
fi

# Check Redis connection
echo -n "Redis: "
if $PYTHON_CMD -c "import redis; r = redis.Redis(host='localhost', port=6379); r.ping()" 2>/dev/null; then
    echo -e "${GREEN}✅ Connected${NC}"
    HAS_REDIS=true
else
    echo -e "${YELLOW}⚠️  Not available (some tests may be skipped)${NC}"
    HAS_REDIS=false
fi

echo ""
echo "========================================="
echo "Running Tests"
echo "========================================="
echo ""

# Determine which tests to run
TEST_TYPE="${1:-all}"
COVERAGE_FLAG=""

if [ "$1" == "--coverage" ] || [ "$2" == "--coverage" ]; then
    COVERAGE_FLAG="--cov --cov-report=html --cov-report=term"
fi

# Run tests based on type
case $TEST_TYPE in
    unit)
        echo "🧪 Running unit tests only..."
        $PYTEST_CMD tests/unit/ -v $COVERAGE_FLAG
        ;;
    integration)
        if [ "$HAS_POSTGRES" == true ]; then
            echo "🔗 Running integration tests..."
            $PYTEST_CMD tests/integration/ -v $COVERAGE_FLAG
        else
            echo -e "${RED}❌ PostgreSQL not available. Cannot run integration tests.${NC}"
            exit 1
        fi
        ;;
    api)
        if [ "$HAS_POSTGRES" == true ]; then
            echo "🌐 Running API tests..."
            $PYTEST_CMD tests/api/ -v $COVERAGE_FLAG
        else
            echo -e "${RED}❌ PostgreSQL not available. Cannot run API tests.${NC}"
            exit 1
        fi
        ;;
    payment)
        echo "💳 Running payment tests..."
        $PYTEST_CMD -m payment -v $COVERAGE_FLAG
        ;;
    --coverage)
        echo "🧪 Running all tests with coverage..."
        $PYTEST_CMD tests/ -v --cov --cov-report=html --cov-report=term
        ;;
    all|*)
        echo "🧪 Running all tests..."
        if [ "$HAS_POSTGRES" == true ]; then
            $PYTEST_CMD tests/ -v $COVERAGE_FLAG
        else
            echo -e "${YELLOW}⚠️  Running unit tests only (PostgreSQL not available)${NC}"
            $PYTEST_CMD tests/unit/ -v $COVERAGE_FLAG
        fi
        ;;
esac

TEST_EXIT_CODE=$?

echo ""
echo "========================================="
echo "Test Results"
echo "========================================="

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo -e "${RED}❌ Some tests failed. Exit code: $TEST_EXIT_CODE${NC}"
fi

# Show coverage report location if generated
if [ -f "htmlcov/index.html" ]; then
    echo ""
    echo "📊 Coverage report generated:"
    echo "   File: $(pwd)/htmlcov/index.html"
    echo "   Open in browser to view detailed coverage"
fi

echo ""
echo "========================================="
echo "Next Steps"
echo "========================================="
echo ""
echo "1. Review test results above"
echo "2. Check coverage report (if generated)"
echo "3. Fix any failing tests"
echo "4. Aim for 70%+ code coverage"
echo "5. Run tests before each commit"
echo ""

exit $TEST_EXIT_CODE
