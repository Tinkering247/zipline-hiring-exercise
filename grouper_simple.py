#!/usr/bin/env python3
"""Simple CSV Grouper using nested loops"""

import csv
import sys
import re

# Check arguments
if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} <input_file> <matching_type>")
    print("\nMatching types:")
    print("  email           - Match records with the same email address")
    print("  phone           - Match records with the same phone number")
    print("  email_or_phone  - Match records with the same email OR phone")
    sys.exit(1)

input_file = sys.argv[1]
matching_type = sys.argv[2]

# Validate matching type
if matching_type not in ['email', 'phone', 'email_or_phone']:
    print(f"Error: Invalid matching type '{matching_type}'")
    sys.exit(1)

# Read CSV file
try:
    with open(input_file, 'r') as f:
        reader = csv.reader(f)
        rows = list(reader)
except FileNotFoundError:
    print(f"Error: File not found '{input_file}'")
    sys.exit(1)

if not rows:
    sys.exit(0)

headers = rows[0]
data_rows = rows[1:]

if not data_rows:
    print(','.join(['PersonID'] + headers))
    sys.exit(0)

# Each row starts with its own group ID
group_ids = list(range(len(data_rows)))

# Extract emails and phones for each row
row_emails = []
row_phones = []

for row in data_rows:
    emails = []
    phones = []

    for i in range(len(headers)):
        header = headers[i]
        if i >= len(row):
            continue

        header_lower = header.lower()
        value = row[i]

        # Collect emails
        if 'email' in header_lower and value and value.strip():
            emails.append(value.strip().lower())

        # Collect phones (extract digits only)
        if 'phone' in header_lower and value and value.strip():
            phone_digits = re.sub(r'\D', '', value)
            if phone_digits:
                phones.append(phone_digits)

    row_emails.append(emails)
    row_phones.append(phones)

# Compare every row with every other row (nested loops)
for i in range(len(data_rows)):
    for j in range(i + 1, len(data_rows)):
        match = False

        # Check if they match based on matching_type
        if matching_type in ['email', 'email_or_phone']:
            # Check if any email matches
            for email_i in row_emails[i]:
                if email_i in row_emails[j]:
                    match = True
                    break

        if not match and matching_type in ['phone', 'email_or_phone']:
            # Check if any phone matches
            for phone_i in row_phones[i]:
                if phone_i in row_phones[j]:
                    match = True
                    break

        # If they match, merge their groups
        if match:
            # Find the smaller group ID
            old_id = max(group_ids[i], group_ids[j])
            new_id = min(group_ids[i], group_ids[j])

            # Update all rows with old_id to new_id (transitive grouping)
            for k in range(len(group_ids)):
                if group_ids[k] == old_id:
                    group_ids[k] = new_id

# Renumber groups to be sequential (1, 2, 3, ...)
unique_groups = sorted(set(group_ids))
group_mapping = {}
for i in range(len(unique_groups)):
    group_mapping[unique_groups[i]] = i + 1
final_group_ids = [group_mapping[gid] for gid in group_ids]

# Output with PersonID
writer = csv.writer(sys.stdout)
writer.writerow(['PersonID'] + headers)
for idx in range(len(data_rows)):
    row = data_rows[idx]
    writer.writerow([str(final_group_ids[idx])] + row)
