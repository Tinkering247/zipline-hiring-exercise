#!/bin/bash
# Verification script to ensure everything is ready for submission

set -e

echo "=========================================="
echo "  CSV Grouper - Verification Script"
echo "=========================================="
echo ""

# Check Docker is available
echo "✓ Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker."
    exit 1
fi
echo "  Docker is installed"
echo ""

# Check files exist
echo "✓ Checking required files..."
required_files=(
    "grouper.rb"
    "test_grouper.rb"
    "Dockerfile"
    "Dockerfile.test"
    "docker-compose.yml"
    "data/input1.csv"
    "data/input2.csv"
    "data/input3.csv"
    "SOLUTION.md"
    "QUICKSTART.md"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing file: $file"
        exit 1
    fi
    echo "  ✓ $file"
done
echo ""

# Build Docker image
echo "✓ Building Docker image..."
docker build -t csv-grouper . > /dev/null 2>&1
echo "  Image built successfully"
echo ""

# Build test image
echo "✓ Building test Docker image..."
mv .dockerignore .dockerignore.bak 2>/dev/null || true
docker build -f Dockerfile.test -t csv-grouper-test . > /dev/null 2>&1
mv .dockerignore.bak .dockerignore 2>/dev/null || true
echo "  Test image built successfully"
echo ""

# Run tests
echo "✓ Running test suite..."
if docker run --rm csv-grouper-test | grep -q "0 failures, 0 errors"; then
    echo "  All tests passed! ✓"
else
    echo "❌ Some tests failed"
    exit 1
fi
echo ""

# Test each input file
echo "✓ Testing input files..."

echo "  Testing data/input1.csv with email..."
if docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input1.csv email > /dev/null 2>&1; then
    echo "    ✓ data/input1.csv (email)"
else
    echo "❌ Failed to process data/input1.csv"
    exit 1
fi

echo "  Testing data/input2.csv with phone..."
if docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input2.csv phone > /dev/null 2>&1; then
    echo "    ✓ data/input2.csv (phone)"
else
    echo "❌ Failed to process data/input2.csv"
    exit 1
fi

echo "  Testing data/input3.csv with email_or_phone..."
if docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input3.csv email_or_phone > /dev/null 2>&1; then
    echo "    ✓ data/input3.csv (email_or_phone)"
else
    echo "❌ Failed to process data/input3.csv"
    exit 1
fi
echo ""

# Check docker-compose
echo "✓ Testing docker-compose..."
if docker-compose run --rm grouper data/input1.csv email > /dev/null 2>&1; then
    echo "  Docker Compose works correctly"
else
    echo "❌ Docker Compose failed"
    exit 1
fi
echo ""

echo "=========================================="
echo "  ✅ All Verifications Passed!"
echo "=========================================="
echo ""
echo "Your solution is ready for submission!"
echo ""
echo "Quick reference:"
echo "  • Run program: docker run --rm -v \"\$(pwd)\":/workspace csv-grouper /workspace/data/input1.csv email"
echo "  • Run tests:   docker run --rm csv-grouper-test"
echo "  • See docs:    cat SOLUTION.md"
echo "  • Quick start: cat QUICKSTART.md"
echo ""
echo "Good luck with your interview! 🚀"
