#!/usr/bin/env python3
"""Simple CSV Grouper - Groups CSV rows that may represent the same person."""

import csv
import sys
import re
from collections import defaultdict

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

# Build Union-Find parent dictionary
parent = {}

# Find with path compression
def find(x):
    if x not in parent:
        parent[x] = x
    if parent[x] != x:
        parent[x] = find(parent[x])
    return parent[x]

# Union two elements
def union(x, y):
    root_x = find(x)
    root_y = find(y)
    if root_x != root_y:
        parent[root_x] = root_y

# Map keys to row indices
key_to_rows = defaultdict(list)

# Process each row
for idx, row in enumerate(data_rows):
    # Extract keys based on matching type
    for i, header in enumerate(headers):
        if i >= len(row):
            continue

        header_lower = header.lower()
        value = row[i]

        # Email matching
        if matching_type in ['email', 'email_or_phone'] and 'email' in header_lower:
            if value and value.strip():
                email = value.strip().lower()
                key_to_rows[f'email:{email}'].append(idx)

        # Phone matching
        if matching_type in ['phone', 'email_or_phone'] and 'phone' in header_lower:
            if value and value.strip():
                phone_digits = re.sub(r'\D', '', value)
                if phone_digits:
                    key_to_rows[f'phone:{phone_digits}'].append(idx)

# Union rows that share any key
for row_indices in key_to_rows.values():
    if len(row_indices) >= 2:
        first = row_indices[0]
        for idx in row_indices[1:]:
            union(first, idx)

# Ensure all rows have a group
for idx in range(len(data_rows)):
    find(idx)

# Group rows by their root
groups = defaultdict(list)
for x in parent:
    groups[find(x)].append(x)

# Assign PersonIDs
row_to_group_id = {}
for group_num, members in enumerate(groups.values(), 1):
    for idx in members:
        row_to_group_id[idx] = group_num

# Output with PersonID
writer = csv.writer(sys.stdout)
writer.writerow(['PersonID'] + headers)
for idx, row in enumerate(data_rows):
    person_id = row_to_group_id[idx]
    writer.writerow([str(person_id)] + row)
