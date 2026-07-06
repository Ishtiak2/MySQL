# MySQL Indexes — A Beginner's Guide

An **index** in MySQL is a special data structure that helps the database find rows much **faster** without scanning the entire table.

> Think of an index in a database like the **index at the back of a textbook**.

---

## Table of Contents

1. [Real-life analogy 📚](#real-life-analogy-)
2. [Example table](#example-table)
3. [Searching without an index](#searching-without-an-index)
4. [Creating an index](#creating-an-index)
5. [How does MySQL store an index?](#how-does-mysql-store-an-index)
6. [Types of indexes](#types-of-indexes)
   - [Primary index](#1-primary-index)
   - [Unique index](#2-unique-index)
   - [Normal index](#3-normal-index)
   - [Composite (multi-column) index](#4-composite-multi-column-index)
7. [Why column order matters](#why-column-order-matters)
8. [Showing indexes](#showing-indexes)
9. [Dropping an index](#dropping-an-index)
10. [Indexes and INSERT](#indexes-and-insert)
11. [Advantages & disadvantages](#advantages--disadvantages)
12. [When should you create an index?](#when-should-you-create-an-index)
13. [When should you avoid an index?](#when-should-you-avoid-an-index)
14. [Complete example](#complete-example)
15. [Summary](#summary)

---

## Real-life analogy 📚

Imagine you have a **1000-page book**. You want to find the topic *"Transactions"*.

### Without an index

You start from page 1 and keep turning pages until you find it.

```
Page 1
Page 2
Page 3
...
Page 587  ← Found
```

**Time taken:** Long.

### With an index

Go to the index at the back:

```
Transactions  →  Page 587
```

Jump **directly** to page 587.

**Time taken:** Very short.

> Databases work the same way:
>
> - **Without an index:** search every row.
> - **With an index:** jump directly to the required rows.

---

## Example table

```sql
CREATE TABLE employees (
    emp_id     INT PRIMARY KEY,
    name       VARCHAR(100),
    department VARCHAR(50),
    salary     DECIMAL(10,2)
);
```

### Sample data

| emp_id | name    | department | salary |
|--------|---------|------------|--------|
| 1      | Alice   | HR         | 50000  |
| 2      | Bob     | IT         | 65000  |
| 3      | Charlie | Finance    | 70000  |
| 4      | David   | IT         | 62000  |
| 5      | Eva     | HR         | 55000  |

---

## Searching without an index

Suppose you execute:

```sql
SELECT *
FROM employees
WHERE department = 'IT';
```

If `department` is **not indexed**, MySQL performs a **full table scan**. It checks every row:

| Row | department | Match? |
|-----|------------|--------|
| 1   | HR         | ❌     |
| 2   | IT         | ✅     |
| 3   | Finance    | ❌     |
| 4   | IT         | ✅     |
| 5   | HR         | ❌     |

Even if the table has **10 million** rows, MySQL checks them one by one.

---

## Creating an index

```sql
CREATE INDEX idx_department
ON employees(department);
```

Now MySQL creates an index on the `department` column.

Conceptually, the index looks like:

| department | Rows         |
|------------|--------------|
| Finance    | Row 3        |
| HR         | Row 1, Row 5 |
| IT         | Row 2, Row 4 |

When you search:

```sql
SELECT *
FROM employees
WHERE department = 'IT';
```

MySQL **consults the index first**:

```
IT  →  Row 2, Row 4
```

It directly accesses those rows instead of scanning the whole table.

---

## How does MySQL store an index?

Most MySQL indexes (InnoDB) are implemented using a **B-Tree**.

Imagine this structure:

```
                 HR
               /    \
         Finance      IT
                     /  \
                 Row2   Row4
```

Instead of checking every row, MySQL **follows the tree** to the matching value. This is much faster for large tables.

---

## Types of indexes

### 1. Primary index

Created **automatically** when you declare a `PRIMARY KEY`.

```sql
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    name   VARCHAR(100)
);
```

`emp_id` is automatically indexed — no need to create another index.

### 2. Unique index

Ensures all values are unique.

```sql
CREATE UNIQUE INDEX idx_email
ON employees(email);
```

Suppose the table contains:

| email            |
|------------------|
| alice@gmail.com  |
| bob@gmail.com    |

Trying to insert a duplicate:

```sql
INSERT INTO employees
VALUES (..., 'alice@gmail.com');
```

Result:

```
ERROR: Duplicate entry
```

### 3. Normal index

Improves search speed.

```sql
CREATE INDEX idx_name
ON employees(name);
```

### 4. Composite (multi-column) index

An index on **multiple columns**.

```sql
CREATE INDEX idx_dept_salary
ON employees(department, salary);
```

This helps queries like:

```sql
SELECT *
FROM employees
WHERE department = 'IT'
  AND salary > 60000;
```

---

## Why column order matters

Suppose the index is:

```
(department, salary)
```

| Query pattern | Index used efficiently? | Why |
|---|---|---|
| `WHERE department = 'IT'` | ✅ Yes | `department` is the **leftmost** column |
| `WHERE department = 'IT' AND salary > 60000` | ✅ Yes | Both columns match the leftmost order |
| `WHERE department = 'IT' ORDER BY salary` | ✅ Yes | Second column is already sorted within the first |
| `WHERE salary > 60000` | ❌ No | Index is ordered by **department** first |

This is known as the **leftmost prefix rule**.

---

## Showing indexes

```sql
SHOW INDEXES
FROM employees;
```

Example output:

| Key_name        | Column_name |
|-----------------|-------------|
| PRIMARY         | emp_id      |
| idx_salary      | salary      |
| idx_department  | department  |

---

## Dropping an index

```sql
DROP INDEX idx_salary
ON employees;
```

The index is removed.

---

## Indexes and INSERT

Indexes speed up **reading** but slightly **slow down writing**.

Suppose you insert:

```sql
INSERT INTO employees
VALUES (6, 'Tom', 'IT', 55000);
```

| Without an index | With an index |
|------------------|----------------|
| Insert row | Insert row |
| Done | Update `salary` index |
| | Update `department` index |
| | Update `name` index |
| | Done |

> Every index must also be updated on every write.

---

## Advantages & disadvantages

### Advantages ✅

- Faster `SELECT` queries
- Faster `WHERE` searches
- Faster joins
- Faster sorting (`ORDER BY`)
- Faster grouping (`GROUP BY`)

### Disadvantages ❌

- Uses additional disk space
- Slower `INSERT`
- Slower `UPDATE` (if indexed columns change)
- Slower `DELETE`

---

## When should you create an index?

Create indexes on columns that are:

- Frequently used in `WHERE` clauses
- Used in `JOIN` conditions
- Used in `ORDER BY`
- Used in `GROUP BY`
- Frequently searched

**Example:**

```sql
SELECT *
FROM orders
WHERE customer_id = 100;
```

If this query runs often, index `customer_id`.

---

## When should you avoid an index?

Avoid indexes on:

- Columns with **very few distinct values** (e.g., `gender` with only Male and Female) — unless combined with other columns in a **composite** index.
- **Very small tables**, where scanning the entire table is already fast.
- Columns that **change very frequently**, since maintaining the index adds overhead.

---

## Complete example

### Step 1: Create the table

```sql
CREATE TABLE students (
    student_id  INT PRIMARY KEY,
    name        VARCHAR(100),
    department  VARCHAR(50)
);
```

### Step 2: Insert data

```sql
INSERT INTO students
VALUES
(1, 'Alice',   'CSE'),
(2, 'Bob',     'EEE'),
(3, 'Charlie', 'CSE'),
(4, 'David',   'BBA');
```

### Step 3: Create an index

```sql
CREATE INDEX idx_department
ON students(department);
```

### Step 4: Search

```sql
SELECT *
FROM students
WHERE department = 'CSE';
```

Without the index MySQL would check every row:

| name    | match |
|---------|-------|
| Alice   | ✓     |
| Bob     | ✗     |
| Charlie | ✓     |
| David   | ✗     |

With the index, MySQL jumps directly:

```
CSE  →  Row 1, Row 3
```

The matching rows are found **much more efficiently**.

---

## Summary

| Concept         | Explanation |
|-----------------|-------------|
| Index           | A data structure that speeds up data retrieval |
| Purpose         | Reduce the number of rows MySQL must examine |
| Automatic index | Created for `PRIMARY KEY` (and `UNIQUE` constraints) |
| Normal index    | Improves search performance |
| Unique index    | Improves search and **prevents duplicate values** |
| Composite index | Index on multiple columns; follows the **leftmost prefix rule** |
| Benefit         | Faster reads (`SELECT`) |
| Cost            | Slower writes (`INSERT`, `UPDATE`, `DELETE`) and extra storage |

> 💡 **Key idea:** An index does **not** store the table's data itself. Instead, it stores an organized structure that helps MySQL quickly locate the rows containing the requested data — much like the index in a book helps you find the right page without reading every page.