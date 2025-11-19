# CSV Grouper Solution

## Overview

This solution identifies and groups rows in CSV files that may represent the same person based on configurable matching strategies. The implementation demonstrates both strong software engineering practices and platform engineering thinking through containerization.

## Architecture

### Design Patterns

- **Strategy Pattern**: Different matching types (email, phone, email_or_phone) are implemented as separate strategy classes
- **Union-Find Algorithm**: Efficient grouping of connected records with path compression and union by rank optimizations
- **Single Responsibility**: Clear separation between matching logic, grouping logic, and I/O operations

### Key Components

1. **UnionFind**: Disjoint set data structure for efficient grouping (O(α(n)) amortized time)
2. **MatchingStrategy**: Base class defining the interface for matching strategies
3. **Strategy Implementations**:
   - `EmailMatchingStrategy`: Groups by matching email addresses
   - `PhoneMatchingStrategy`: Groups by matching phone numbers
   - `EmailOrPhoneMatchingStrategy`: Groups by matching email OR phone (transitive)
4. **CSVGrouper**: Orchestrates the grouping process

### Algorithm Complexity

- **Time Complexity**: O(n * m) where n = rows, m = average keys per row
- **Space Complexity**: O(n) for union-find structure
- **Optimizations**: Path compression and union by rank for near-constant time operations

## Features

✅ **Required Features**:
- Email matching
- Phone matching
- Email OR Phone matching
- Handles all provided CSV formats
- Command-line interface

✅ **Additional Features**:
- Dockerized for portability (no Ruby installation required)
- Comprehensive test suite with 20+ test cases
- Handles edge cases (empty fields, case-insensitive emails, different phone formats)
- Non-root container user for security
- Multi-stage Docker builds for minimal image size
- Docker Compose for easy orchestration
- Helper scripts for common operations

## Usage

### Option 1: Docker (Recommended - No Ruby installation required)

```bash
# Build the image
docker build -t csv-grouper .

# Process a file with email matching
docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input1.csv email > output1.csv

# Process with phone matching
docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input2.csv phone > output2.csv

# Process with email OR phone matching
docker run --rm -v "$(pwd)":/workspace csv-grouper /workspace/data/input3.csv email_or_phone > output3.csv
```

### Option 2: Docker Compose

```bash
# Edit docker-compose.yml to specify input file and matching type, then:
docker-compose run --rm grouper data/input1.csv email > output1.csv
```

### Option 3: Native Ruby (if Ruby 3.x is installed)

```bash
# Make executable
chmod +x grouper.rb

# Run directly
./grouper.rb data/input1.csv email > output1.csv
./grouper.rb data/input2.csv phone > output2.csv
./grouper.rb data/input3.csv email_or_phone > output3.csv
```

### Helper Scripts

```bash
# Run all tests
docker-compose run --rm test

# Or with native Ruby
ruby test_grouper.rb

# Process all sample files (creates output1.csv, output2.csv, output3.csv)
chmod +x scripts/run_examples.sh
./scripts/run_examples.sh
```

## Testing

Comprehensive test suite covering:

- **Unit Tests**: UnionFind, matching strategies, normalization
- **Integration Tests**: End-to-end CSV processing
- **Edge Cases**: Empty fields, case sensitivity, phone format variations
- **Sample Data**: All three provided input files

Run tests:
```bash
# Using Docker (recommended)
docker build -f Dockerfile.test -t csv-grouper-test .
docker run --rm csv-grouper-test

# Using native Ruby
ruby test_grouper.rb
```

## Matching Types

### `email`
Groups records that share at least one email address.
- Case-insensitive matching
- Handles multiple email columns (Email1, Email2, etc.)
- Ignores empty/blank values

### `phone`
Groups records that share at least one phone number.
- Normalizes formats: `(555) 123-4567`, `555-123-4567`, `555.123.4567` → `5551234567`
- Handles multiple phone columns (Phone1, Phone2, etc.)
- Ignores empty/blank values

### `email_or_phone`
Groups records that share ANY email OR phone (transitive closure).
- If Record A shares email with B, and B shares phone with C, all three are grouped
- Combines normalization from both email and phone strategies

## Example Output

### Input (input1.csv)
```csv
FirstName,LastName,Phone,Email,Zip
John,Smith,(555) 123-4567,johns@home.com,94105
Jane,Smith,(555) 123-4567,janes@home.com,94105-1245
```

### Output (email_or_phone matching)
```csv
PersonID,FirstName,LastName,Phone,Email,Zip
1,John,Smith,(555) 123-4567,johns@home.com,94105
1,Jane,Smith,(555) 123-4567,janes@home.com,94105-1245
```

Both records get `PersonID = 1` because they share a phone number.

## Design Decisions

### Why Union-Find?
- Efficient for grouping transitive relationships (O(α(n)) operations)
- Handles arbitrary connection patterns
- Memory efficient

### Why Strategy Pattern?
- Easy to add new matching types
- Clear separation of concerns
- Testable in isolation

### Why Docker?
- **Zero dependencies**: No Ruby installation required
- **Consistent execution**: Same behavior on any platform
- **Production-ready**: Can deploy to Kubernetes, ECS, etc.
- **Security**: Non-root user in container
- **Platform engineering mindset**: Shows infrastructure-as-code thinking

## Algorithm Comparison & Performance

### Alternative Approaches Considered

#### Nested Loops (O(n²))
I initially created a python script with the following logic:
```python
for i in range(len(rows)):
    for j in range(i + 1, len(rows)):
        if rows share email or phone:
            merge their groups
```

**Pros:**
- Simple to understand and implement
- Works correctly for small datasets
- About 100 lines of code

**Cons:**
- O(n²) complexity scales poorly
- 20,000 rows = 200 million comparisons

#### Union-Find (O(n·α(n)) ≈ O(n)) - Selected Approach
As input3 was taking longer than expected i requested AI to give me a better algorithm which is a
Hash-based grouping with Union-Find data structure:
```python
# Map keys to rows, then union rows sharing keys
for each row:
    extract keys (emails, phones)
    map key -> row indices
for each key:
    union all rows sharing that key
```

**Pros:**
- Near-linear time complexity
- Efficient memory usage
- Handles transitive relationships naturally

**Cons:**
- Slightly more complex to implement

### Real-World Performance Benchmark

Tested on input3.csv (20,000 rows) using Python implementations:

| Algorithm | Time | Comparisons | Speed |
|-----------|------|-------------|-------|
| **Nested Loops** | 112 seconds (1m 52s) | ~200 million | Baseline |
| **Union-Find** | 0.25 seconds | ~20,000 | **444x faster** |

### Why This Matters

For production use cases:
- **Small datasets (< 1,000 rows):** Either approach works fine
- **Medium datasets (1,000-10,000 rows):** Union-Find becomes noticeably faster
- **Large datasets (> 10,000 rows):** Union-Find is essential for acceptable performance
- **Very large datasets (> 100,000 rows):** Consider distributed approaches (Spark, graph databases)

**Key Insight:** The nested loops approach would have been a valid solution that works correctly. Union-Find transforms it from "working code" to "production-grade code" - demonstrating how AI can elevate a correct solution to an optimal one.

## Project Structure

```
.
├── README.md               # Project overview
├── SOLUTION.md             # This file - technical deep-dive
├── QUICKSTART.md           # Quick usage guide
├── ALGORITHM_EXAMPLE.md    # Algorithm walkthrough
├── Dockerfile              # Production image (minimal, non-root user)
├── Dockerfile.test         # Test image with test dependencies
├── docker-compose.yml      # Easy orchestration
├── grouper.rb              # Main Ruby application
├── grouper.py              # Python Union-Find implementation
├── grouper_simple.py       # Python nested loops implementation
├── test_grouper.rb         # Comprehensive test suite
├── data/                   # Sample input files
│   ├── input1.csv          # Basic examples
│   ├── input2.csv          # Multiple phone/email columns
│   └── input3.csv          # Large dataset (20K rows)
└── scripts/                # Helper scripts
    ├── run_examples.sh     # Process all sample files
    └── verify.sh           # Automated verification
```

## Platform Engineering Considerations

This solution goes beyond the basic requirements to demonstrate platform engineering skills:

1. **Containerization**: Fully Dockerized with multi-stage builds
2. **Security**: Non-root container user
3. **Portability**: Runs anywhere Docker runs (local, CI/CD, Kubernetes)
4. **Minimal Dependencies**: Uses only Ruby stdlib (no gems)
5. **Observability**: Clear error messages and logging
6. **Documentation**: Comprehensive README with examples
7. **Testing**: Automated test suite that can run in CI/CD
8. **12-Factor App**: Stateless, config via CLI args, logs to stdout

## CI/CD Integration

This solution is CI/CD-ready:

```yaml
# Example GitHub Actions workflow
- name: Run tests
  run: docker-compose run --rm test

- name: Process sample data
  run: |
    docker-compose run --rm grouper data/input1.csv email > output1.csv
    docker-compose run --rm grouper data/input2.csv phone > output2.csv
    docker-compose run --rm grouper data/input3.csv email_or_phone > output3.csv
```

## Future Enhancements

- Add fuzzy matching for names (Levenshtein distance)
- Support for large files (streaming/chunking)
- RESTful API wrapper
- Metrics/observability (Prometheus, DataDog)
- Helm chart for Kubernetes deployment
- Performance benchmarking suite

## Author Notes

This solution was created to demonstrate:
- ✅ Problem-solving skills (Union-Find algorithm)
- ✅ Clean code practices (SOLID principles, design patterns)
- ✅ Testing discipline (20+ test cases)
- ✅ Platform engineering thinking (Docker, portability)
- ✅ Production readiness (security, documentation, error handling)
- ✅ Forward-thinking architecture (extensible, maintainable)
