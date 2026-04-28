#!/bin/bash

# ==================== LMS DOCKER TESTING SCRIPT ====================
# This script runs tests in a Docker container with all dependencies
# This is the RECOMMENDED way to run tests as it ensures consistency
#
# Usage:
#   ./scripts/run_tests_docker.sh              # Run all tests
#   ./scripts/run_tests_docker.sh unit         # Run unit tests only
#   ./scripts/run_tests_docker.sh --coverage   # Run with coverage
#
# Requirements:
#   - Docker and Docker Compose installed

set -e

cd "$(dirname "$0")/.." || exit 1

echo "========================================="
echo "LMS Docker Testing Script"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo "✅ Docker is running"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ docker-compose.yml not found${NC}"
    exit 1
fi

echo "✅ docker-compose.yml found"
echo ""

# Start dependencies (database, redis)
echo "========================================="
echo "Starting Test Dependencies"
echo "========================================="
echo ""

echo "🚀 Starting PostgreSQL and Redis..."
docker-compose up -d db redis

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose exec -T db pg_isready -U lms_user > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ PostgreSQL failed to start${NC}"
        docker-compose logs db
        exit 1
    fi
    sleep 1
done

# Wait for Redis to be ready
echo "⏳ Waiting for Redis to be ready..."
for i in {1..10}; do
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Redis is ready${NC}"
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}❌ Redis failed to start${NC}"
        docker-compose logs redis
        exit 1
    fi
    sleep 1
done

echo ""
echo "========================================="
echo "Running Tests in Docker"
echo "========================================="
echo ""

# Build backend image if needed
echo "🏗️  Building backend image..."
docker-compose build backend

# Determine test command
TEST_TYPE="${1:-all}"
COVERAGE_FLAG=""

if [ "$1" == "--coverage" ] || [ "$2" == "--coverage" ]; then
    COVERAGE_FLAG="--cov --cov-report=html --cov-report=term"
fi

# Construct pytest command
case $TEST_TYPE in
    unit)
        PYTEST_ARGS="tests/unit/ -v $COVERAGE_FLAG"
        ;;
    integration)
        PYTEST_ARGS="tests/integration/ -v $COVERAGE_FLAG"
        ;;
    api)
        PYTEST_ARGS="tests/api/ -v $COVERAGE_FLAG"
        ;;
    payment)
        PYTEST_ARGS="-m payment -v $COVERAGE_FLAG"
        ;;
    --coverage)
        PYTEST_ARGS="tests/ -v --cov --cov-report=html --cov-report=term"
        ;;
    all|*)
        PYTEST_ARGS="tests/ -v $COVERAGE_FLAG"
        ;;
esac

# Run tests in Docker container
echo "🧪 Running tests: pytest $PYTEST_ARGS"
echo ""

docker-compose run --rm \
    -e DJANGO_SETTINGS_MODULE=lms_project.settings_test \
    -e DB_HOST=db \
    -e CELERY_BROKER_URL=redis://redis:6379/0 \
    backend \
    pytest $PYTEST_ARGS

TEST_EXIT_CODE=$?

echo ""
echo "========================================="
echo "Test Results"
echo "========================================="
echo ""

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo -e "${RED}❌ Some tests failed. Exit code: $TEST_EXIT_CODE${NC}"
fi

# Copy coverage report from container if generated
if echo "$COVERAGE_FLAG" | grep -q "cov-report=html"; then
    echo ""
    echo "📊 Copying coverage report from container..."

    # Get the container ID of the last run
    CONTAINER_ID=$(docker-compose ps -q backend | head -1)

    if [ -n "$CONTAINER_ID" ]; then
        docker cp ${CONTAINER_ID}:/app/htmlcov backend/htmlcov 2>/dev/null || true
        if [ -d "backend/htmlcov" ]; then
            echo "   Coverage report: $(pwd)/backend/htmlcov/index.html"
        fi
    fi
fi

echo ""
echo "========================================="
echo "Cleanup"
echo "========================================="
echo ""

# Ask if user wants to stop services
read -p "Stop database and Redis? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🛑 Stopping services..."
    docker-compose down
    echo "✅ Services stopped"
else
    echo "ℹ️  Services still running. Run 'docker-compose down' to stop them."
fi

echo ""
echo "========================================="
echo "Summary"
echo "========================================="
echo ""
echo "Tests completed with exit code: $TEST_EXIT_CODE"
echo ""

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ All tests passed!"
    echo ""
    echo "Next steps:"
    echo "  1. Review coverage report (if generated)"
    echo "  2. Ensure coverage is above 70%"
    echo "  3. Run tests before each commit"
else
    echo "❌ Tests failed. Please fix the failing tests."
    echo ""
    echo "Debug steps:"
    echo "  1. Review error messages above"
    echo "  2. Check test logs: docker-compose logs backend"
    echo "  3. Run specific test: ./scripts/run_tests_docker.sh unit"
fi

echo ""

exit $TEST_EXIT_CODE
