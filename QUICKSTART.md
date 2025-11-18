# Quick Start Guide

## Running the Solution

### Option 1: Docker (No Ruby Installation Required) ⭐ Recommended

```bash
# Build the image
docker build -t csv-grouper .

# Run with different matching types
docker run --rm -v "$(pwd)":/data csv-grouper /data/input1.csv email
docker run --rm -v "$(pwd)":/data csv-grouper /data/input2.csv phone
docker run --rm -v "$(pwd)":/data csv-grouper /data/input3.csv email_or_phone

# Save output to file
docker run --rm -v "$(pwd)":/data csv-grouper /data/input1.csv email_or_phone > output.csv
```

### Option 2: Docker Compose

```bash
# Run with docker-compose
docker-compose run --rm grouper input1.csv email

# Run tests
docker-compose run --rm test
```

### Option 3: Native Ruby (if installed)

```bash
chmod +x grouper.rb
./grouper.rb input1.csv email > output.csv
```

## Running Tests

```bash
# With Docker
docker build -f Dockerfile.test -t csv-grouper-test .
docker run --rm csv-grouper-test

# With native Ruby
ruby test_grouper.rb
```

## Matching Types

- `email` - Groups records by matching email addresses
- `phone` - Groups records by matching phone numbers
- `email_or_phone` - Groups records by matching email OR phone (transitive)

## Example

```bash
$ docker run --rm -v "$(pwd)":/data csv-grouper /data/input1.csv email_or_phone

PersonID,FirstName,LastName,Phone,Email,Zip
1,John,Smith,(555) 123-4567,johns@home.com,94105
1,Jane,Smith,(555) 123-4567,janes@home.com,94105-1245
2,Jack,Smith,444.123.4567,jacks@home.com,94105
...
```

Rows with the same PersonID represent the same person.
