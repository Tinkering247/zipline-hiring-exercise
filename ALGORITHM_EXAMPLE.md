# Algorithm Walkthrough - Visual Example

Use this to explain how the solution works step-by-step.

---

## Sample Input (input1.csv simplified)

```csv
FirstName,LastName,Phone,Email
John,Smith,555-1234,john@email.com
Jane,Smith,555-1234,jane@email.com
Jack,Smith,555-9999,john@email.com
Jill,Doe,555-7777,jill@email.com
```

---

## Step 1: Parse CSV

```
Row 0: John, Smith, 555-1234, john@email.com
Row 1: Jane, Smith, 555-1234, jane@email.com
Row 2: Jack, Smith, 555-9999, john@email.com
Row 3: Jill, Doe,   555-7777, jill@email.com
```

---

## Step 2: Extract Keys (email_or_phone strategy)

```
Row 0: ["phone:5551234", "email:john@email.com"]
Row 1: ["phone:5551234", "email:jane@email.com"]
Row 2: ["phone:5559999", "email:john@email.com"]
Row 3: ["phone:5557777", "email:jill@email.com"]
```

---

## Step 3: Build Key-to-Rows Mapping

```
phone:5551234       → [Row 0, Row 1]    (John and Jane share phone)
email:john@email.com → [Row 0, Row 2]    (John and Jack share email)
phone:5559999       → [Row 2]
email:jane@email.com → [Row 1]
phone:5557777       → [Row 3]
email:jill@email.com → [Row 3]
```

---

## Step 4: Union-Find Operations

### Initial State
```
Each row is its own group:
Row 0: parent=0
Row 1: parent=1
Row 2: parent=2
Row 3: parent=3
```

### Operation 1: Process phone:5551234 → [Row 0, Row 1]
```
union(0, 1)

Result:
Row 0: parent=0  ← Root
Row 1: parent=0  (points to Row 0)
Row 2: parent=2
Row 3: parent=3

Groups: {0: [0,1], 2: [2], 3: [3]}
```

**Visual:**
```
    0 (Root)
    |
    1

2 (Root)   3 (Root)
```

### Operation 2: Process email:john@email.com → [Row 0, Row 2]
```
union(0, 2)

Result:
Row 0: parent=0  ← Root
Row 1: parent=0
Row 2: parent=0  (now points to Row 0)
Row 3: parent=3

Groups: {0: [0,1,2], 3: [3]}
```

**Visual:**
```
      0 (Root)
     / \
    1   2

3 (Root)
```

### Operation 3: Process other keys (no new unions)
```
phone:5559999 → [Row 2] (only one row, no union)
email:jane@email.com → [Row 1] (only one row, no union)
phone:5557777 → [Row 3] (only one row, no union)
email:jill@email.com → [Row 3] (only one row, no union)

Final state unchanged:
Groups: {0: [0,1,2], 3: [3]}
```

---

## Step 5: Assign Group IDs

```
Group 0 → PersonID 1
  - Row 0 (John)
  - Row 1 (Jane)
  - Row 2 (Jack)

Group 3 → PersonID 2
  - Row 3 (Jill)
```

---

## Step 6: Generate Output

```csv
PersonID,FirstName,LastName,Phone,Email
1,John,Smith,555-1234,john@email.com
1,Jane,Smith,555-1234,jane@email.com
1,Jack,Smith,555-9999,john@email.com
2,Jill,Doe,555-7777,jill@email.com
```

---

## Why They're Grouped

### Group 1 (John, Jane, Jack):
```
John ←---same phone---→ Jane
  ↑
  same email
  ↓
Jack
```

- John and Jane share phone **555-1234**
- John and Jack share email **john@email.com**
- Therefore: **John = Jane = Jack** (transitive closure)

### Group 2 (Jill):
- Jill shares nothing with anyone
- She's in her own group

---

## Key Insight: Transitive Closure

This is why Union-Find shines:

**Question:** Do Jane and Jack represent the same person?

**Analysis:**
- Jane and Jack don't share email ❌
- Jane and Jack don't share phone ❌
- **BUT:** Jane → (phone) → John → (email) → Jack ✅

**Answer:** Yes! They're connected through John.

**Union-Find automatically handles this** - when we union(John, Jane) and union(John, Jack), the find() operation returns the same root for all three.

---

## Comparison: Without Union-Find

### Naive Approach (O(n²))
```python
# Compare every pair
for i in range(len(rows)):
    for j in range(i+1, len(rows)):
        if shares_anything(rows[i], rows[j]):
            # What group are they in?
            # How to merge groups?
            # Complex bookkeeping!
```

**Problems:**
- Slow for large datasets
- Complex group merging logic
- Hard to maintain

### With Union-Find (O(n))
```python
# Build connections incrementally
for key, row_indices in key_to_rows.items():
    first = row_indices[0]
    for other in row_indices[1:]:
        union(first, other)  # Simple!

# Groups are automatically merged
groups = union_find.groups()
```

**Benefits:**
- Fast (near-linear time)
- Simple merging (just call union)
- Clean code

---

## Path Compression Visualization

### Without Path Compression
```
After many unions, tree could look like:

    0
    |
    1
    |
    2
    |
    3
    |
    4

find(4) walks: 4→3→2→1→0 (5 steps)
```

### With Path Compression
```
After find(4), tree becomes:

      0
    / | \ \
   1  2  3  4

find(4) next time: 4→0 (2 steps)
All future finds are faster!
```

This is why Union-Find is O(α(n)) instead of O(log n).

---

## Real Input Example: input2.csv

```csv
FirstName,LastName,Phone1,Phone2,Email1,Email2
John,Doe,555-1234,555-9876,john@home.com,
Jane,Doe,555-1234,555-6549,jane@home.com,john@home.com
Jack,Doe,444-1234,555-6549,jack@home.com,
```

### Keys Extracted
```
John: [phone:5551234, phone:5559876, email:john@home.com]
Jane: [phone:5551234, phone:5556549, email:jane@home.com, email:john@home.com]
Jack: [phone:4441234, phone:5556549, email:jack@home.com]
```

### Connections
```
John ←--phone:5551234-→ Jane
John ←-email:john@home.com→ Jane
Jane ←--phone:5556549--→ Jack
```

### Result
All three grouped together! (Jane is the "bridge")

---

## Practice Explanation

**Interviewer:** "Explain how your algorithm groups these rows."

**You:** "Let me walk through an example. We have four people - John, Jane, Jack, and Jill.

First, I extract identifying keys from each row - phone numbers and emails, normalized to handle format differences.

Then I use a Union-Find data structure to build groups. When John and Jane share a phone number, I union them. When John and Jack share an email, I union them. Union-Find automatically handles the transitive relationship - now Jane and Jack are connected through John, even though they don't directly share anything.

The beauty of Union-Find is it does this efficiently - near-linear time with path compression optimization. At the end, I have groups of connected rows, assign each group a PersonID, and output the result.

Jill doesn't share anything with anyone, so she gets her own group."

**Interviewer:** "Why not just compare each row to every other row?"

**You:** "That would be O(n²) - for 20,000 rows, that's 400 million comparisons. With Union-Find, it's effectively O(n) - just 20,000 operations. Plus, Union-Find elegantly handles the transitive relationships without complex bookkeeping."

---

## Whiteboard-Ready Diagram

If asked to diagram the solution:

```
┌──────────────────────────────────────────┐
│            INPUT CSV                     │
│  FirstName, LastName, Phone, Email      │
└─────────────────┬────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         Parse Rows + Headers            │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│      Apply Matching Strategy            │
│   (extract & normalize keys)            │
│                                         │
│  Row 0 → [phone:5551234, email:john]   │
│  Row 1 → [phone:5551234, email:jane]   │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│     Build Key → Rows Mapping            │
│                                         │
│  phone:5551234 → [Row 0, Row 1]        │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│       Union-Find Algorithm              │
│                                         │
│  For each key with multiple rows:      │
│    union(row1, row2, ...)              │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         Extract Groups                  │
│  Group 1: [Row 0, Row 1, Row 2]        │
│  Group 2: [Row 3]                      │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│      Assign PersonIDs & Output          │
│                                         │
│  PersonID, FirstName, LastName, ...    │
│  1, John, Smith, ...                   │
│  1, Jane, Smith, ...                   │
└─────────────────────────────────────────┘
```

---

## Bottom Line

**Union-Find** + **Strategy Pattern** + **Normalization** = Efficient, Extensible, Robust Solution

Practice explaining this flow and you'll ace any technical questions! 🎯
