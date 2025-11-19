#!/bin/bash
# Helper script to run all example inputs with Docker

set -e

echo "Building Docker image..."
docker build -t csv-grouper .

echo ""
echo "Processing input1.csv with email matching..."
docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input1.csv email > output1_email.csv
echo "✓ Created output1_email.csv"

echo ""
echo "Processing input1.csv with phone matching..."
docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input1.csv phone > output1_phone.csv
echo "✓ Created output1_phone.csv"

echo ""
echo "Processing input1.csv with email_or_phone matching..."
docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input1.csv email_or_phone > output1_email_or_phone.csv
echo "✓ Created output1_email_or_phone.csv"

echo ""
echo "Processing input2.csv with email matching..."
docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input2.csv email > output2_email.csv
echo "✓ Created output2_email.csv"

echo ""
echo "Processing input2.csv with phone matching..."
docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input2.csv phone > output2_phone.csv
echo "✓ Created output2_phone.csv"

echo ""
echo "Processing input2.csv with email_or_phone matching..."
docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input2.csv email_or_phone > output2_email_or_phone.csv
echo "✓ Created output2_email_or_phone.csv"

echo ""
echo "Processing input3.csv with email_or_phone matching..."
docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input3.csv email_or_phone > output3_email_or_phone.csv
echo "✓ Created output3_email_or_phone.csv"

echo ""
echo "=========================================="
echo "All examples processed successfully!"
echo "=========================================="
echo "Output files created:"
ls -lh output*.csv
