# MySQL Triggers — A Beginner's Guide

A hands-on, section-by-section walkthrough of MySQL **triggers** with simple explanations and runnable examples.

> **How to read this guide:** each sub-section has a short plain-English explanation followed by a small example you can paste into MySQL Workbench, the `mysql` client, or any GUI. The examples all share one small sample schema so you can build it once and reuse it.

---

## Table of Contents

- **Section 1. Introduction to MySQL Triggers**
- **Section 2. Managing MySQL Triggers**
  - 2.1 Creating a trigger
  - 2.2 Dropping (removing) a trigger
- **Section 3. Create a BEFORE INSERT trigger**
- **Section 4. AFTER INSERT trigger**
- **Section 5. BEFORE UPDATE trigger**
- **Section 6. AFTER UPDATE trigger**
- **Section 7. BEFORE DELETE trigger**
- **Section 8. AFTER DELETE trigger**
- **Section 9. Multiple triggers for the same event and time (MySQL 8.0+)**
- **Section 10. Listing (SHOW) triggers**

---

## The sample schema we will use

We will use one small **library** schema for almost every example. Run this once before any other snippet in this guide:

```sql
CREATE DATABASE IF NOT EXISTS trigger_demo;
USE trigger_demo;

-- Main table: books
DROP TABLE IF EXISTS books;
CREATE TABLE books (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    title       VARCHAR(150) NOT NULL,
    author      VARCHAR(100) NOT NULL,
    price       DECIMAL(10,2) NOT NULL,
    in_stock    INT NOT NULL DEFAULT 0   -- how many copies we currently have
);

INSERT INTO books (title, author, price, in_stock) VALUES
('The Hobbit',          'J.R.R. Tolkien', 12.50, 10),
('Dune',                'Frank Herbert',   15.00,  5),
('Clean Code',          'Robert C. Martin',30.00,  2),
('The Pragmatic Coder', 'Andy Hunt',       28.00,  7);

-- Summary table kept in sync by triggers in Section 3
DROP TABLE IF EXISTS books_stock_summary;
CREATE TABLE books_stock_summary (
    total_books   INT NOT NULL DEFAULT 0,
    total_in_stock INT NOT NULL DEFAULT 0,
    last_updated  DATETIME DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO books_stock_summary (total_books, total_in_stock)
VALUES (0, 0);

-- Audit log used by Section 6 (AFTER UPDATE)
DROP TABLE IF EXISTS books_audit;
CREATE TABLE books_audit (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    book_id     INT,
    old_price   DECIMAL(10,2),
    new_price   DECIMAL(10,2),
    changed_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    changed_by  VARCHAR(100)                 -- filled in by the trigger (Section 6)
);

-- Tombstone / archive table used by Section 8 (AFTER DELETE)
DROP TABLE IF EXISTS books_archive;
CREATE TABLE books_archive (
    id          INT,
    title       VARCHAR(150),
    author      VARCHAR(100),
    price       DECIMAL(10,2),
    deleted_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

You now have four tables to play with:

| Table | What it is for |
|-------|---------------|
| `books`              | The main table we will be inserting / updating / deleting |
| `books_stock_summary`| A 1-row "dashboard" table that always reflects totals in `books` |
| `books_audit`        | A log that records every price change |
| `books_archive`      | A copy of any book we delete (so history is not lost) |

---

# Section 1. Introduction to MySQL Triggers

## 1.1 What is a trigger?

A **trigger** is a small block of SQL that the database runs **automatically** whenever a row in a table is **inserted**, **updated**, or **deleted**.

> Think of it like a **doorbell**: you don't ring it yourself every time someone arrives — it rings itself, because it is wired to the door.

Three important facts:

1. A trigger is **attached to one specific table**. You cannot make one trigger that watches two tables.
2. A trigger fires **once per row**, not once per statement (unless you ask for `FOR EACH ROW` vs the older `FOR EACH STATEMENT`).
3. Inside a trigger you can read the old and new values of the row using `OLD` and `NEW` aliases.

## 1.2 When do triggers fire?

A trigger is defined for a combination of:

- **Event** — what happened?
  - `INSERT`
  - `UPDATE`
  - `DELETE`
- **Time** — when should it run, relative to the event?
  - `BEFORE` — run *before* the row is written
  - `AFTER`  — run *after* the row is written

So there are 6 possible shapes:

| Event | When |
|-------|------|
| `INSERT` | `BEFORE INSERT` or `AFTER INSERT` |
| `UPDATE` | `BEFORE UPDATE` or `AFTER UPDATE` |
| `DELETE` | `BEFORE DELETE` or `AFTER DELETE` |

(`UPDATE` and `DELETE` triggers also let you use `OLD.col_name`. `INSERT` triggers only let you use `NEW.col_name`. `UPDATE` triggers let you use **both**.)

## 1.3 BEFORE vs AFTER — when to use which?

| | `BEFORE` | `AFTER` |
|---|----------|---------|
| Runs **before** the row is saved | ✅ | ❌ |
| Runs **after** the row is saved  | ❌ | ✅ |
| Can **change** `NEW.col` values  | ✅ | ❌ (too late) |
| Good for **validating / fixing** data | ✅ | — |
| Good for **logging / cascading** to other tables | — | ✅ |

A simple rule of thumb:

- Use `BEFORE` when you want to **clean or reject** the data **before** it lands.
- Use `AFTER` when you want to **react** to the data being saved (log it, update another table, etc.).

## 1.4 Why use triggers?

| Advantages ✅ | Disadvantages ❌ |
|---|---|
| Enforce rules that the app cannot forget | Hidden logic — easy to forget they exist |
| Keep summary / audit tables in sync automatically | Hard to debug (no `SELECT` results inside a trigger) |
| Run on the server → close to the data | Can slow down bulk `INSERT` / `UPDATE` / `DELETE` |
| Centralised "if this happens, do that" rules | Cannot call stored procedures that return result sets |

---

# Section 2. Managing MySQL Triggers

## 2.1 Creating a trigger — the basic steps

Creating a trigger is a 4-step recipe. Let's go through it slowly.

### Step 1 — Pick the **table**, the **event**, and the **time**

Ask yourself:

1. Which table am I watching?  → `books`
2. What action?                → `INSERT`, `UPDATE`, or `DELETE`
3. Before or after that action? → `BEFORE` or `AFTER`

For our first trigger we will pick: **books, BEFORE INSERT**.

### Step 2 — Choose a **name**

The name has to be unique in the whole database. A common pattern is:

```
{table}_{event}_{time}_{what_it_does}
```

Examples: `books_before_insert_strip_whitespace`, `orders_after_update_log_change`.

### Step 3 — Write the body

A trigger body is a single `BEGIN ... END` block (or just one statement).

### Step 4 — Run it

You do **not** change the delimiter for triggers the way you do for stored procedures — the parser already understands `CREATE TRIGGER ... END;`. You just write:

```sql
DELIMITER is not needed for triggers
```

So the final shape is:

```sql
CREATE TRIGGER trigger_name
    {BEFORE | AFTER} {INSERT | UPDATE | DELETE}
    ON table_name
    FOR EACH ROW
BEGIN
    -- one or more SQL statements
END;
```

> 📝 **Note:** `FOR EACH ROW` is the only allowed option in MySQL — MySQL does not support `FOR EACH STATEMENT` triggers.

### A first, harmless example

This trigger **strips leading/trailing spaces** from a book's title and author before the row is inserted:

```sql
DROP TRIGGER IF EXISTS books_before_insert_trim;

CREATE TRIGGER books_before_insert_trim
    BEFORE INSERT
    ON books
    FOR EACH ROW
BEGIN
    SET NEW.title  = TRIM(NEW.title);
    SET NEW.author = TRIM(NEW.author);
END;

-- Try it
INSERT INTO books (title, author, price, in_stock)
VALUES ('  Refactoring  ', '  Martin Fowler ', 35.00, 3);

SELECT id, title, author FROM books;
```

Notice how the trigger **mutated `NEW.title` and `NEW.author`**. Because the trigger is `BEFORE INSERT`, those cleaned-up values are what actually get stored. If we had used `AFTER INSERT`, it would have been too late.

### Anatomy of the CREATE TRIGGER statement

```
CREATE TRIGGER  books_before_insert_trim       ← name (must be unique)
    BEFORE INSERT                              ← time + event
    ON books                                   ← table it watches
    FOR EACH ROW                               ← fires once per affected row
BEGIN
    SET NEW.title  = TRIM(NEW.title);          ← body — references NEW row
END;
```

### Things you are NOT allowed to do inside a trigger

These are easy to forget — keep them in mind:

| Not allowed | Why |
|---|---|
| `CALL` a stored procedure that returns a result set | Result sets can't be sent back from a trigger |
| `START TRANSACTION`, `COMMIT`, `ROLLBACK` | The outer statement already controls transactions |
| `RETURN` (as in a function) | Triggers don't return values |
| `SELECT ... INTO` from a `FOR EACH ROW` trigger in some versions without care | It works, but is slow |

## 2.2 Dropping (removing) a trigger

When you don't need a trigger any more, drop it:

```sql
DROP TRIGGER IF EXISTS books_before_insert_trim;
```

- `IF EXISTS` is optional — it just avoids an error if the trigger doesn't exist.
- You drop a trigger **by name only**. There is no `DROP TRIGGER ... ON table;` syntax in MySQL (some other databases work that way).
- You need the **`TRIGGER`** privilege on the table, plus `DROP` privilege on the schema.
- Dropping a trigger does **not** touch the table's data — it only removes the automatic behaviour.

### Verify it is gone

```sql
SHOW TRIGGERS;                -- lists all triggers in the current database
SHOW TRIGGERS LIKE 'books%';  -- filter by name pattern
SHOW CREATE TRIGGER trigger_name;  -- exact definition (handy to copy before dropping!)
```

> 💡 **Tip:** before dropping, run `SHOW CREATE TRIGGER your_trigger;` so you have the exact `CREATE TRIGGER` statement saved — useful if you need to recreate it later. We will see `SHOW TRIGGERS` in detail in Section 10.

### Quick recap

- A trigger is created with `CREATE TRIGGER name {BEFORE|AFTER} {INSERT|UPDATE|DELETE} ON table FOR EACH ROW BEGIN ... END;`.
- You don't change the delimiter for triggers.
- `DROP TRIGGER [IF EXISTS] name;` removes a trigger by its name only.
- Use `SHOW TRIGGERS` or `SHOW CREATE TRIGGER` to find/inspect them.

---

> **Next:** when you are ready, we'll continue with **Section 3 — Create a BEFORE INSERT trigger to maintain a summary table from another table**.

---

# Section 3. Create a BEFORE INSERT trigger

## 3.1 What we want to build

Imagine you have a dashboard that shows **total number of books** and **total copies in stock**. You don't want to run a heavy `SUM()` query every time the page loads — you want a tiny summary row that is **already updated** whenever someone inserts a new book.

That is a perfect job for a trigger:

- Whenever a new row is `INSERT`ed into `books`,
- **before** the row is saved, update the totals in `books_stock_summary`.

So the dashboard query becomes a simple `SELECT * FROM books_stock_summary` — instant.

## 3.2 The plan

```
books (INSERT)
   │
   └── BEFORE INSERT trigger fires
            │
            └── recomputes and stores totals in books_stock_summary
```

Because the trigger fires **before** the insert, we can:

- read `NEW.in_stock` (the value that is about to be inserted),
- add it to the existing `total_in_stock` in the summary table,
- add `1` to `total_books`.

After the trigger finishes, the row is actually inserted. The summary stays in sync.

## 3.3 The trigger

```sql
DROP TRIGGER IF EXISTS books_before_insert_update_summary;

DELIMITER $$

CREATE TRIGGER books_before_insert_update_summary
    BEFORE INSERT
    ON books
    FOR EACH ROW
BEGIN
    UPDATE books_stock_summary
    SET total_books    = total_books + 1,
        total_in_stock = total_in_stock + NEW.in_stock
    -- (no WHERE clause — there is exactly one row in the summary table)
    ;
END$$

DELIMITER ;
```

A few things to notice:

- **`BEFORE INSERT`** lets us use `NEW.in_stock` because the row hasn't been written yet — but we could also read `NEW` in an `AFTER INSERT` trigger, so the choice here is mostly stylistic. `BEFORE` is a good fit because we are *preparing* the related state.
- We used a single `UPDATE` on a 1-row table — no `WHERE` is needed because there is only ever one summary row.
- The trigger body lives in its own `BEGIN ... END` block, even though it only has one statement. It is a good habit — you will easily add more statements later.

## 3.4 Try it out

```sql
-- Current state of the summary
SELECT * FROM books_stock_summary;
-- total_books = 0, total_in_stock = 0  (empty)

-- Insert a new book
INSERT INTO books (title, author, price, in_stock)
VALUES ('Refactoring', 'Martin Fowler', 35.00, 4);

-- The summary should now reflect the change
SELECT * FROM books_stock_summary;
-- total_books = 1, total_in_stock = 4
```

Run a few more inserts and watch the numbers grow:

```sql
INSERT INTO books (title, author, price, in_stock) VALUES
('Domain-Driven Design', 'Eric Evans',     40.00, 3),
('The Mythical Man-Month', 'Fred Brooks',  22.50, 6);

SELECT * FROM books_stock_summary;
-- total_books = 3, total_in_stock = 13
```

## 3.5 Why not just use a formula or `GENERATED` column?

Great question. MySQL supports **generated columns** that auto-compute a value from other columns *in the same row*:

```sql
price_with_tax DECIMAL(10,2) GENERATED ALWAYS AS (price * 1.1)
```

That's perfect for **row-level** calculations. But our summary needs to **aggregate across all rows** (totals), which is exactly what triggers are good at. Generated columns cannot see other rows, only the row they live in.

| Need | Tool |
|---|---|
| Compute one column from other columns in the same row | `GENERATED ALWAYS AS` column |
| Aggregate across rows, kept up to date | Trigger + summary table |
| Validate one row before it lands | `BEFORE INSERT/UPDATE` trigger |
| React to a row landing (log, replicate, etc.) | `AFTER INSERT/UPDATE/DELETE` trigger |

## 3.6 A safer pattern — keep using BEFORE to set values

The example above updated **another table** from a `BEFORE INSERT` trigger. The *more classic* use of `BEFORE INSERT` is to fix `NEW` itself before the row is saved. Here is a small extra that fixes the title to title-case and rejects negative prices:

```sql
DROP TRIGGER IF EXISTS books_before_insert_clean;

DELIMITER $$

CREATE TRIGGER books_before_insert_clean
    BEFORE INSERT
    ON books
    FOR EACH ROW
BEGIN
    -- 1. Trim and title-case the title
    SET NEW.title = TRIM(NEW.title);

    -- 2. Reject negative prices with a clear error (Section 5 will go deeper)
    IF NEW.price < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Price cannot be negative';
    END IF;
END$$

DELIMITER ;
```

Notice how **mutating `NEW`** is the clean way to use `BEFORE INSERT` — the values you change here are the values that get stored.

## 3.7 Quick recap

- `BEFORE INSERT` triggers run **before** a new row is saved.
- Use `NEW.column_name` to read — and modify — the values that are about to be inserted.
- Great for:
  - cleaning/trimming data,
  - rejecting bad data with `SIGNAL`,
  - updating **other** tables that depend on this one (summaries, counters, dashboards).
- A trigger cannot use transaction-control statements (`COMMIT`, `ROLLBACK`) — the outer statement handles that.

---

> **Next:** when you are ready, we'll continue with **Section 4 — Create an AFTER INSERT trigger that inserts a row into a related table**.