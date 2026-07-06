# MySQL Views — A Beginner's Guide

A **view** in MySQL is a **virtual table** created from the result of a SQL query.

| | What it is |
|---|---|
| A **real table** | Stores data physically in the database. |
| A **view** | Does **not** store data (MySQL has no materialized views). It simply stores the **SQL query**. Whenever you query the view, MySQL executes that query and returns the **latest** data from the underlying tables. |

> Think of it like this:
>
> - **Table** → "Data is stored here."
> - **View** → "Only stores: `SELECT … FROM …`"

---

## Table of Contents

1. [Why use views?](#why-use-views)
2. [Basic syntax](#basic-syntax)
3. [Example database](#example-database)
4. [Example 1 — Create a simple view](#example-1--create-a-simple-view)
5. [Example 2 — View with `WHERE`](#example-2--view-with-where)
6. [Example 3 — View with `JOIN`](#example-3--view-with-join)
7. [Example 4 — View with calculated columns](#example-4--view-with-calculated-columns)
8. [Updating data through a view](#updating-data-through-a-view)
9. [When is a view updatable?](#when-is-a-view-updatable)
10. [`ALTER VIEW` — change a view](#alter-view--change-a-view)
11. [`CREATE OR REPLACE VIEW`](#create-or-replace-view)
12. [`DROP VIEW` — delete a view](#drop-view--delete-a-view)
13. [Seeing all views](#seeing-all-views)
14. [Advantages of views](#advantages-of-views)
15. [Disadvantages of views](#disadvantages-of-views)
16. [Real-life example — banking](#real-life-example--banking)
17. [Summary](#summary)

---

## Why use views?

Views make databases easier to use by:

- ✅ Hiding complex SQL queries
- ✅ Improving readability
- ✅ Restricting access to sensitive columns
- ✅ Reusing common queries
- ✅ Providing abstraction

## Basic syntax

```sql
CREATE VIEW view_name AS
SELECT column1, column2, ...
FROM table_name
WHERE condition;
```

## Example database

We will use one small `employees` schema. Run this once before the other snippets:

```sql
CREATE DATABASE IF NOT EXISTS view_demo;
USE view_demo;

DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    emp_id      INT PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL,
    department  VARCHAR(50)  NOT NULL,
    salary      DECIMAL(10,2) NOT NULL
);

INSERT INTO employees (name, department, salary) VALUES
('Alice',   'HR',    50000.00),
('Bob',     'IT',    70000.00),
('Charlie', 'IT',    65000.00),
('David',   'Sales', 45000.00);
```

You should see this data:

| emp_id | name    | department | salary   |
|--------|---------|------------|----------|
| 1      | Alice   | HR         | 50000.00 |
| 2      | Bob     | IT         | 70000.00 |
| 3      | Charlie | IT         | 65000.00 |
| 4      | David   | Sales      | 45000.00 |

---

## Example 1 — Create a simple view

Suppose we frequently need only **employee names** and **departments**. Instead of writing

```sql
SELECT name, department
FROM employees;
```

every time, let's create a view:

```sql
CREATE VIEW employee_info AS
SELECT name, department
FROM employees;
```

Now simply do:

```sql
SELECT * FROM employee_info;
```

**Output**

| name    | department |
|---------|------------|
| Alice   | HR         |
| Bob     | IT         |
| Charlie | IT         |
| David   | Sales      |

### What actually happens?

The view stores **only this query**:

```sql
SELECT name, department
FROM employees;
```

When you run

```sql
SELECT * FROM employee_info;
```

MySQL internally runs

```sql
SELECT name, department
FROM employees;
```

So the data is **always up-to-date**.

---

## Example 2 — View with `WHERE`

Create a view containing only `IT` employees:

```sql
CREATE VIEW it_employees AS
SELECT *
FROM employees
WHERE department = 'IT';
```

Now:

```sql
SELECT * FROM it_employees;
```

**Output**

| emp_id | name    | department | salary   |
|--------|---------|------------|----------|
| 2      | Bob     | IT         | 70000.00 |
| 3      | Charlie | IT         | 65000.00 |

### What if the table changes?

Suppose you insert a new row:

```sql
INSERT INTO employees
VALUES
(5, 'Eva', 'IT', 80000.00);
```

Now run the same select against the view:

```sql
SELECT * FROM it_employees;
```

**Output**

| emp_id | name    | department | salary   |
|--------|---------|------------|----------|
| 2      | Bob     | IT         | 70000.00 |
| 3      | Charlie | IT         | 65000.00 |
| 5      | Eva     | IT         | 80000.00 |

> Notice we never updated the view. The view always reflects the **latest** table data.

---

## Example 3 — View with `JOIN`

Suppose we have **two** tables.

### `departments`

| dept_id | department |
|---------|------------|
| 1       | HR         |
| 2       | IT         |
| 3       | Sales      |

### `employees`

| emp_id | name    | dept_id | salary   |
|--------|---------|---------|----------|
| 1      | Alice   | 1       | 50000.00 |
| 2      | Bob     | 2       | 70000.00 |
| 3      | Charlie | 2       | 65000.00 |

Normally we'd write

```sql
SELECT
    e.name,
    d.department,
    e.salary
FROM employees e
JOIN departments d
    ON e.dept_id = d.dept_id;
```

Instead, create a view:

```sql
CREATE VIEW employee_details AS
SELECT
    e.name,
    d.department,
    e.salary
FROM employees e
JOIN departments d
    ON e.dept_id = d.dept_id;
```

Now:

```sql
SELECT * FROM employee_details;
```

No need to write the JOIN repeatedly.

---

## Example 4 — View with calculated columns

```sql
CREATE VIEW salary_bonus AS
SELECT
    name,
    salary,
    salary * 0.10 AS bonus
FROM employees;
```

Query:

```sql
SELECT * FROM salary_bonus;
```

**Output**

| name  | salary   | bonus     |
|-------|----------|-----------|
| Alice | 50000.00 | 5000.0000 |
| Bob   | 70000.00 | 7000.0000 |

> The bonus is **calculated every time** you query the view.

---

## Updating data through a view

Suppose:

```sql
CREATE VIEW employee_names AS
SELECT emp_id, name
FROM employees;
```

You can update **through** the view:

```sql
UPDATE employee_names
SET name = 'Robert'
WHERE emp_id = 2;
```

### What actually happens?

MySQL updates the **original table**:

```
employee_names  ──►  employees table updated
```

---

## When is a view updatable?

A view is generally **updatable** if it is based on a **single table** and doesn't include operations that make updates ambiguous.

### Updatable view

```sql
CREATE VIEW employee_view AS
SELECT emp_id, name, salary
FROM employees;
```

You can run `INSERT`, `UPDATE`, and `DELETE` **through** this view.

### Non-updatable view

```sql
CREATE VIEW total_salary AS
SELECT department,
       SUM(salary)
FROM employees
GROUP BY department;
```

**Why?** There is no **single row** in `employees` that corresponds to a grouped result.

### Other things that make a view non-updatable

A view is generally **not** updatable if it contains any of the following:

- `GROUP BY`
- Aggregate functions (`SUM`, `AVG`, `COUNT`, …)
- `DISTINCT`
- `UNION`
- Many complex joins
- Subqueries in the `SELECT` list

---

## `ALTER VIEW` — change a view

Change the **query stored in a view**.

Instead of:

```sql
CREATE VIEW employee_info AS
SELECT name, department
FROM employees;
```

Suppose you also want `salary`:

```sql
ALTER VIEW employee_info AS
SELECT
    name,
    department,
    salary
FROM employees;
```

Now

```sql
SELECT * FROM employee_info;
```

returns **three** columns.

---

## `CREATE OR REPLACE VIEW`

If you want to create the view **if it doesn't exist** or **replace it** if it does:

```sql
CREATE OR REPLACE VIEW employee_info AS
SELECT
    name,
    salary
FROM employees;
```

If the view exists, it is replaced. Otherwise, it is created.

> This is the most common way to "update" a view definition in production scripts.

---

## `DROP VIEW` — delete a view

```sql
DROP VIEW employee_info;
```

The **original table remains unchanged**. Only the view is removed.

---

## Seeing all views

```sql
SHOW FULL TABLES
WHERE Table_type = 'VIEW';
```

Or — for the exact definition of a single view:

```sql
SHOW CREATE VIEW employee_info;
```

This displays the SQL definition of the view.

---

## Advantages of views

| Advantage         | Explanation                                                                 |
|-------------------|-----------------------------------------------------------------------------|
| Simplifies queries | Avoid repeating long SQL statements.                                         |
| Security          | Hide sensitive columns such as salaries or passwords.                       |
| Consistency       | Everyone uses the same query logic.                                         |
| Abstraction       | Applications are less affected by changes to underlying tables.             |
| Reusability       | Write once, use many times.                                                  |

## Disadvantages of views

| Disadvantage              | Explanation                                                                |
|---------------------------|----------------------------------------------------------------------------|
| No data storage           | The query runs each time, which can hurt performance for complex views.   |
| Complex views may be slow | Views with many joins or calculations can be expensive to execute.        |
| Some views are read-only  | Not all views support `INSERT`, `UPDATE`, or `DELETE`.                    |
| Dependency on tables      | If referenced tables or columns are removed or changed incompatibly, the view may stop working. |

---

## Real-life example — banking

Imagine a banking database.

### `customers`

| id | name  | account | balance | password |
|----|-------|---------|---------|----------|
| 1  | Alice | 101     | 100000  | abc123   |

Employees should **not** see customer passwords.

Instead of giving them direct access to the table:

```sql
SELECT *
FROM customers;
```

Create a view:

```sql
CREATE VIEW customer_info AS
SELECT
    id,
    name,
    account,
    balance
FROM customers;
```

Employees then query:

```sql
SELECT * FROM customer_info;
```

They see

| id | name  | account | balance |
|----|-------|---------|---------|
| 1  | Alice | 101     | 100000  |

The `password` column remains hidden — improving security.

---

## Summary

- A **view** is a virtual table based on a `SELECT` query.
- It does **not** store data; it stores the query **definition**.
- Views **simplify** complex SQL and **improve security** by exposing only selected columns.
- They always show the **latest data** from the underlying tables.
- **Simple** views are often **updatable**, while views using aggregates, `GROUP BY`, `DISTINCT`, `UNION`, or other complex constructs are generally **read-only**.
- Use `CREATE VIEW`, `ALTER VIEW`, `CREATE OR REPLACE VIEW`, and `DROP VIEW` to manage views.
