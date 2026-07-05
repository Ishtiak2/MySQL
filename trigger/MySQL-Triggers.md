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
- **Section 4. Create an AFTER INSERT trigger**
- **Section 5. Create a BEFORE UPDATE trigger**
- **Section 6. Create an AFTER UPDATE trigger**
- **Section 7. Create a BEFORE DELETE trigger**
- **Section 8. Create an AFTER DELETE trigger**
- **Section 9. Multiple triggers for the same event and time (MySQL 8.0+)**
- **Section 10. Show triggers — listing and patterns**

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

---

# Section 4. Create an AFTER INSERT trigger

## 4.1 What we want to build

In Section 3 we used a `BEFORE INSERT` trigger to **prepare** things. Now we want to use `AFTER INSERT` to **react** to the new row landing.

A common real-world pattern:

> Whenever a new book is added, automatically create a "default review" row for it — so reviewers can immediately add their feedback without any extra setup.

This is a perfect fit for `AFTER INSERT`:

- We need the **`id`** of the newly-inserted book — that value is only available **after** the row is saved (auto-increment happens during `INSERT`).
- We want to insert a row into **another** table (`book_reviews`) based on the new book.

## 4.2 A small extra table

Add this to the setup schema (or run it now):

```sql
DROP TABLE IF EXISTS book_reviews;
CREATE TABLE book_reviews (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    book_id     INT NOT NULL,
    reviewer    VARCHAR(100) DEFAULT 'pending',
    rating      TINYINT,             -- 1..5 stars
    comment     VARCHAR(500),
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 4.3 BEFORE vs AFTER for this job

| | `BEFORE INSERT` | `AFTER INSERT` |
|---|---|---|
| `NEW.id` available? | ❌ — auto-increment not yet assigned | ✅ |
| Good for inserting into a related table? | Possible, but risky — if the outer `INSERT` later fails, the related row is already there | ✅ — runs only if the outer `INSERT` succeeded |

> 📌 **Important:** if the outer `INSERT` fails (e.g. a constraint violation), an `AFTER INSERT` trigger does **not** fire. That is exactly what you want for "do something *because* a new row was really saved".

## 4.4 The trigger

```sql
DROP TRIGGER IF EXISTS books_after_insert_create_review;

DELIMITER $$

CREATE TRIGGER books_after_insert_create_review
    AFTER INSERT
    ON books
    FOR EACH ROW
BEGIN
    INSERT INTO book_reviews (book_id, reviewer, rating, comment)
    VALUES (
        NEW.id,           -- the id of the book that just landed
        'pending',        -- no reviewer yet
        NULL,             -- no rating yet
        NULL              -- no comment yet
    );
END$$

DELIMITER ;
```

Read it slowly:

- `AFTER INSERT` on `books` — fires once per inserted row.
- `NEW.id` — only valid here because `AFTER` means the row is already saved and its `AUTO_INCREMENT` is assigned.
- We `INSERT` a placeholder review row so the book is immediately "reviewable".

## 4.5 Try it out

```sql
-- Look at reviews before
SELECT * FROM book_reviews;          -- (empty)

-- Add a book
INSERT INTO books (title, author, price, in_stock)
VALUES ('Clean Architecture', 'Robert C. Martin', 32.00, 5);

-- A review row was created automatically
SELECT * FROM book_reviews;
-- id=1, book_id=<new book's id>, reviewer='pending', rating=NULL, ...
```

Add a couple more books to see the trigger fire for each:

```sql
INSERT INTO books (title, author, price, in_stock) VALUES
('The Phoenix Project', 'Gene Kim',     24.00, 4),
('Site Reliability Engineering', 'Google', 45.00, 2);

SELECT b.id, b.title, r.reviewer, r.rating
FROM books b
LEFT JOIN book_reviews r ON r.book_id = b.id
ORDER BY b.id;
```

You should see one review row per book.

## 4.6 AFTER INSERT can do more than insert

The trigger can run **any** SQL statement — `INSERT`, `UPDATE`, even `DELETE` on other tables. Common uses:

| Use case | What the trigger does |
|---|---|
| Create related default rows | `INSERT` into a child table (our example) |
| Update a counter / dashboard | `UPDATE` a totals row |
| Send a notification row | `INSERT` into a `notifications` / `outbox` table |
| Push to an audit / history | `INSERT` into an audit table |
| Mirror to another DB (via FEDERATED / app) | `INSERT` into a remote-style table |

## 4.7 What if the trigger itself fails?

Two important guarantees from MySQL:

1. If the trigger body fails (e.g. `SIGNAL SQLSTATE ...`), the **outer `INSERT` is rolled back**. The book row will **not** be saved. This is exactly the behaviour you want for "all or nothing".
2. The trigger runs in the same transaction as the triggering statement — so an `AFTER` trigger that fails prevents the data from being committed.

This makes `AFTER INSERT` triggers a safe place to put "must-always-happen" side effects.

## 4.8 Quick recap

- `AFTER INSERT` triggers run **after** a row is successfully written.
- Use them when you need the row's **`id`** (auto-increment value) or when you want to **react** to the insert.
- They cannot mutate `NEW` (the row is already saved).
- If the trigger fails, the original `INSERT` is rolled back too — so your data stays consistent.
- Great for: creating default related rows, updating counters, pushing to audit tables, etc.

---

> **Next:** when you are ready, we'll continue with **Section 5 — Create a BEFORE UPDATE trigger that validates data before it is updated**.

---

# Section 5. Create a BEFORE UPDATE trigger

## 5.1 What we want to build

A `BEFORE UPDATE` trigger runs **before** an existing row is changed. That makes it the right place for **validation** — the same way `BEFORE INSERT` is.

Real-world example: we want to make sure **nobody can**:

1. Set a book's price to a **negative** value, and
2. Reduce `in_stock` by more copies than we currently have (otherwise we'd go negative in stock).

If either rule is broken, we should **reject the `UPDATE`** with a clear error — and the original row should stay exactly as it was.

## 5.2 OLD vs NEW inside an UPDATE trigger

This is the big new idea for `UPDATE` triggers — you can see **both**:

| Alias | Meaning |
|---|---|
| `OLD.col_name` | the value **before** the update (what the row looked like) |
| `NEW.col_name` | the value **after** the update (what the row is about to become) |

Because we run **before** the update, `NEW` is still mutable — we can change it (like in `BEFORE INSERT`) or reject it.

```
UPDATE books SET price = -5 WHERE id = 1;
                  │
                  └── BEFORE UPDATE trigger
                          OLD.price = 12.50   ← currently in the DB
                          NEW.price = -5.00   ← about to be written
                          → SIGNAL 'price cannot be negative'
                          → outer UPDATE is rolled back
```

## 5.3 The trigger

```sql
DROP TRIGGER IF EXISTS books_before_update_validate;

DELIMITER $$

CREATE TRIGGER books_before_update_validate
    BEFORE UPDATE
    ON books
    FOR EACH ROW
BEGIN
    -- Rule 1: price must be >= 0
    IF NEW.price < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Price cannot be negative';
    END IF;

    -- Rule 2: in_stock must never go below 0
    IF NEW.in_stock < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'in_stock cannot be negative';
    END IF;
END$$

DELIMITER ;
```

Two things to notice:

- We use `SIGNAL SQLSTATE '45000'` to raise a custom error. `45000` is the conventional SQLSTATE for "user-defined error". The `MESSAGE_TEXT` becomes the error message MySQL shows you.
- Raising `SIGNAL` **aborts** the statement. The row is not updated. The DB stays clean.

## 5.4 Try it out

```sql
-- 1. A valid update — should succeed
UPDATE books SET price = 19.99 WHERE title = 'Dune';
SELECT id, title, price FROM books WHERE title = 'Dune';
-- price is now 19.99

-- 2. An invalid update — should be rejected
UPDATE books SET price = -1.00 WHERE title = 'Dune';
-- ERROR 1644 (45000): Price cannot be negative

-- 3. Verify the row was NOT changed
SELECT id, title, price FROM books WHERE title = 'Dune';
-- price is still 19.99 ✅

-- 4. Another invalid update — negative stock
UPDATE books SET in_stock = -5 WHERE title = 'The Hobbit';
-- ERROR 1644 (45000): in_stock cannot be negative
```

That last check is important — **`BEFORE UPDATE` triggers are all-or-nothing**. If the trigger raises an error, the row is unchanged.

## 5.5 A more useful pattern — auto-cap a value

Validation is one use. Another classic `BEFORE UPDATE` job is **fixing** values silently. For example, **never let the discount price be more than 50% of the original** — clamp it automatically:

```sql
DROP TRIGGER IF EXISTS books_before_update_clamp_price;

DELIMITER $$

CREATE TRIGGER books_before_update_clamp_price
    BEFORE UPDATE
    ON books
    FOR EACH ROW
BEGIN
    -- If someone tries to cut the price in half or more, keep at least 50%
    IF NEW.price < OLD.price * 0.5 THEN
        SET NEW.price = OLD.price * 0.5;
    END IF;
END$$

DELIMITER ;

UPDATE books SET price = 1.00 WHERE title = 'The Hobbit'; -- original 12.50
SELECT title, price FROM books WHERE title = 'The Hobbit';
-- price is now 6.25 (= 12.50 * 0.5), not 1.00 — the trigger clamped it
```

> ⚠️ Whether you **reject** bad data (with `SIGNAL`) or **silently fix it** (by mutating `NEW`) is a design choice. `SIGNAL` is loud and safer; clamping is convenient but can hide bugs.

## 5.6 Things you CANNOT do in a BEFORE UPDATE trigger

- Reference **other tables' columns directly** in the trigger's column-list (you can `SELECT` from them in the body, just not in the `UPDATE ... SET` form).
- Call a stored procedure that returns a result set.
- Use `START TRANSACTION` / `COMMIT` / `ROLLBACK`.

## 5.7 Quick recap

- `BEFORE UPDATE` triggers run **before** an existing row is overwritten.
- You have access to **both** `OLD` (current value) and `NEW` (incoming value).
- Use it to **validate** (with `SIGNAL`) or **silently fix** (by mutating `NEW`).
- Raising an error inside the trigger means the update is rolled back — the row stays unchanged.

---

# Section 6. Create an AFTER UPDATE trigger

## 6.1 What we want to build

Now we flip the script: **after** a row is updated, we want to **log** what changed. This is one of the most common uses of triggers in real systems — auditing.

Real-world example: every time the **price** of a book changes, write a row to `books_audit` showing:

- which book (`book_id`),
- the old price,
- the new price,
- when it happened (`changed_at`, filled by the table default),
- who did it (`changed_by` — we'll grab it from the MySQL session).

After the trigger runs, you can answer: *"Who changed the price of "Dune" last week, and from what to what?"* — by simply `SELECT`ing from the audit table.

## 6.2 BEFORE vs AFTER for an audit log

| | `BEFORE UPDATE` | `AFTER UPDATE` |
|---|---|---|
| `OLD.price`, `NEW.price` both visible? | ✅ | ✅ |
| Know the update will actually happen? | ❌ (it could still fail later) | ✅ |
| Risk of writing a phantom audit row? | ✅ — possible | ❌ — only fires if the row was really updated |

For an audit log, you almost always want `AFTER UPDATE` — you don't want to log changes that never happened.

## 6.3 The trigger

```sql
DROP TRIGGER IF EXISTS books_after_update_log_price;

DELIMITER $$

CREATE TRIGGER books_after_update_log_price
    AFTER UPDATE
    ON books
    FOR EACH ROW
BEGIN
    -- Only log when the price actually changed (avoid noise from other column updates)
    IF OLD.price <> NEW.price THEN
        INSERT INTO books_audit (book_id, old_price, new_price, changed_by)
        VALUES (
            OLD.id,
            OLD.price,
            NEW.price,
            CURRENT_USER()         -- the user who ran the UPDATE
        );
    END IF;
END$$

DELIMITER ;
```

Reading it slowly:

- `AFTER UPDATE` on `books` — fires once per *updated row*.
- `OLD.id` — the book's id (it's the same on both sides, but `OLD` is conventional for "the row we knew").
- `IF OLD.price <> NEW.price` — only log meaningful changes; if someone updates only the title, we skip the audit row.
- `CURRENT_USER()` — the MySQL function that returns the currently logged-in user. **You can call it inside a trigger**, you just can't use it as a column default (we saw that in Section 1's setup).

## 6.4 Try it out

```sql
-- Make sure the audit table is empty
SELECT * FROM books_audit;   -- (empty)

-- 1. Update a book — price changes
UPDATE books SET price = 18.50 WHERE title = 'Dune';

-- 2. Look at the audit row
SELECT * FROM books_audit;
-- book_id=<id of Dune>, old_price=19.99, new_price=18.50, changed_by='root@localhost'

-- 3. Update again — another row appears
UPDATE books SET price = 17.00 WHERE title = 'Dune';

SELECT * FROM books_audit ORDER BY id;
-- 2 rows now, each with a different (old_price, new_price) pair

-- 4. Update something that ISN'T the price — no audit row should be written
UPDATE books SET title = 'Dune (2nd ed.)' WHERE title = 'Dune';

SELECT COUNT(*) AS price_changes FROM books_audit;
-- Still 2 — the title-only update was skipped ✅
```

That last check is important — your audit table only contains **real** price changes.

## 6.5 Pattern: only audit certain columns

The `IF OLD.col <> NEW.col` guard is how you keep an audit table focused. You can extend this to a list:

```sql
IF (OLD.price <> NEW.price)
   OR (OLD.title <> NEW.title)
   OR (OLD.author <> NEW.author) THEN
   -- log
END IF;
```

## 6.6 What if the UPDATE matches 0 rows?

Good news: **no trigger fires** if the `UPDATE` matches no rows. So you don't have to worry about phantom "I updated a row that doesn't exist" entries in your audit log.

## 6.7 Quick recap

- `AFTER UPDATE` triggers run **after** an existing row is overwritten — and **only if the row was actually changed**.
- You have both `OLD` (was) and `NEW` (now).
- Use them for **audit logs**, propagating changes to other tables, and similar "react to a real change" jobs.
- Guard with `IF OLD.col <> NEW.col` to avoid noisy logs when other columns change.

---

> **Next:** when you are ready, we'll continue with **Section 7 — Create a BEFORE DELETE trigger**.

---

# Section 7. Create a BEFORE DELETE trigger

## 7.1 What we want to build

A `BEFORE DELETE` trigger runs **before** a row is removed from the table. That makes it the right place to:

1. **Block deletes** that would break a business rule.
2. Look at the row that is about to disappear (via `OLD`) and decide what to do.

A real-world rule for a library:

> You are not allowed to delete a book that is still in the catalog with stock > 0. Otherwise someone could lose money by accidentally removing a title that still has copies on the shelf.

If the rule is broken, the trigger raises a clear error and the row is **not** deleted.

## 7.2 OLD inside a DELETE trigger

Unlike `INSERT` (which has `NEW`) and `UPDATE` (which has both), a `DELETE` trigger only has **`OLD`**. The row is being thrown away — there is no "new" version of it.

```
DELETE FROM books WHERE id = 1;
              │
              └── BEFORE DELETE trigger
                      OLD.id, OLD.title, OLD.price, OLD.in_stock  ← still readable
                      → if OLD.in_stock > 0 → SIGNAL 'cannot delete'
```

Inside a `BEFORE DELETE` trigger you can **read** `OLD.*` freely, and you can still abort the operation with `SIGNAL`. But you cannot "save" the row from being deleted by mutating anything — `OLD` is read-only.

## 7.3 The trigger

```sql
DROP TRIGGER IF EXISTS books_before_delete_block_in_stock;

DELIMITER $$

CREATE TRIGGER books_before_delete_block_in_stock
    BEFORE DELETE
    ON books
    FOR EACH ROW
BEGIN
    IF OLD.in_stock > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete a book that still has copies in stock';
    END IF;
END$$

DELIMITER ;
```

Reading it:

- `BEFORE DELETE` on `books` — fires once per row about to be deleted.
- `OLD.in_stock` — the value currently in the DB, before the row goes away.
- If the rule is violated, `SIGNAL SQLSTATE '45000'` raises a user-defined error and the row stays put.

## 7.4 Try it out

```sql
-- Look at current stock for our books
SELECT id, title, in_stock FROM books;
-- e.g. The Hobbit (10), Dune (5), Clean Code (2), ...

-- 1. Try to delete a book that still has stock → should fail
DELETE FROM books WHERE title = 'The Hobbit';
-- ERROR 1644 (45000): Cannot delete a book that still has copies in stock

-- 2. Verify the row is still there
SELECT id, title FROM books WHERE title = 'The Hobbit';
-- Still present ✅

-- 3. Set stock to 0 first, then delete → should succeed
UPDATE books SET in_stock = 0 WHERE title = 'The Hobbit';
DELETE FROM books WHERE title = 'The Hobbit';

SELECT id, title FROM books WHERE title = 'The Hobbit';
-- Now gone
```

That last flow is the "happy path": when the rule allows the delete, the row is removed normally — the trigger doesn't get in the way.

## 7.5 A different kind of BEFORE DELETE — overwrite before it's gone

`BEFORE DELETE` can also be used to **move** the row to an archive (we will see that more cleanly in Section 8 with `AFTER DELETE`), but here's a quick preview using `BEFORE`:

```sql
DROP TRIGGER IF EXISTS books_before_delete_copy_to_archive;

DELIMITER $$

CREATE TRIGGER books_before_delete_copy_to_archive
    BEFORE DELETE
    ON books
    FOR EACH ROW
BEGIN
    INSERT INTO books_archive (id, title, author, price)
    VALUES (OLD.id, OLD.title, OLD.author, OLD.price);
END$$

DELIMITER ;
```

> ⚠️ This works, but most teams prefer `AFTER DELETE` for archiving — see Section 8 for why (a `BEFORE` trigger can still be aborted by another trigger further down the chain; `AFTER` only runs after the row is truly gone).

## 7.6 Bulk DELETEs

`BEFORE DELETE` fires **once per row** — even for `DELETE FROM books WHERE ...` that matches thousands of rows. That means:

- If 5000 rows match, the trigger body runs 5000 times.
- Each `SIGNAL` aborts the **entire statement** — not just the one offending row. The whole `DELETE` is rolled back.
- If you want row-by-row resilience ("skip bad rows, delete the rest"), use `AFTER DELETE` plus a handler — but that is more advanced and outside this section's scope.

## 7.7 Quick recap

- `BEFORE DELETE` runs **before** a row is removed.
- Inside, you can read `OLD.*` (the about-to-be-deleted row) — `NEW` does not exist here.
- Use it to **block** deletes that break a rule (via `SIGNAL`).
- The rule applies **per row**; one failing row fails the whole statement.

---

# Section 8. Create an AFTER DELETE trigger

## 8.1 What we want to build

Now the symmetric case: **after** a row is successfully deleted, we want to **archive** it. This is one of the most common real-world uses of `AFTER DELETE`:

> When a book is removed from `books`, copy its full record into `books_archive` so we still have a history. (Useful for compliance, analytics, "undo", etc.)

After this section, every time you `DELETE` a book, you'll have a permanent tombstone in `books_archive`.

## 8.2 BEFORE vs AFTER for archiving

| | `BEFORE DELETE` | `AFTER DELETE` |
|---|---|---|
| Row still in `books`? | ✅ yes | ❌ already gone |
| Has access to `OLD.*`? | ✅ | ✅ |
| Fires only if the delete really happened? | ❌ — another trigger could still abort it | ✅ |
| Good for archiving? | Works, but less safe | ✅ the canonical choice |

Rule of thumb: **archive in `AFTER DELETE`, validate in `BEFORE DELETE`**.

## 8.3 The trigger

```sql
DROP TRIGGER IF EXISTS books_after_delete_archive;

DELIMITER $$

CREATE TRIGGER books_after_delete_archive
    AFTER DELETE
    ON books
    FOR EACH ROW
BEGIN
    INSERT INTO books_archive (id, title, author, price)
    VALUES (OLD.id, OLD.title, OLD.author, OLD.price);
END$$

DELIMITER ;
```

That's it — `AFTER DELETE` + `OLD` = "the row that just disappeared".

## 8.4 Try it out

```sql
-- Clear archive first so the demo is clean
TRUNCATE TABLE books_archive;

-- Pick a book we know we can delete (still in stock — but our rule in Section 7
-- would block it). Let's temporarily drop that rule so this section is self-contained:
DROP TRIGGER IF EXISTS books_before_delete_block_in_stock;

-- 1. Delete a book
DELETE FROM books WHERE title = 'Clean Code';

-- 2. The row is gone from books...
SELECT title FROM books WHERE title = 'Clean Code';   -- empty result

-- 3. ...but it lives on in books_archive
SELECT * FROM books_archive;
-- id=3 (or whatever), title='Clean Code', author='Robert C. Martin', price=30.00, deleted_at=<now>
```

Note the `deleted_at` column — it has a `DEFAULT CURRENT_TIMESTAMP` from our schema setup, so we get the deletion time for free.

## 8.5 Cascade-style: archive AND log

You can stack multiple `AFTER DELETE` triggers on the same event in MySQL 8.0+ (Section 9). But even without that, a single trigger can do multiple things:

```sql
DROP TRIGGER IF EXISTS books_after_delete_archive;

DELIMITER $$

CREATE TRIGGER books_after_delete_archive
    AFTER DELETE
    ON books
    FOR EACH ROW
BEGIN
    -- 1. Tombstone the row
    INSERT INTO books_archive (id, title, author, price)
    VALUES (OLD.id, OLD.title, OLD.author, OLD.price);

    -- 2. Log who did it (for audit)
    INSERT INTO books_audit (book_id, old_price, new_price, changed_by)
    VALUES (OLD.id, OLD.price, OLD.price,    -- same price twice — deletion, not a price change
            CONCAT('deleted by ', CURRENT_USER()));
END$$

DELIMITER ;
```

That single trigger gives you both **history** (archive) and **who/when** (audit).

## 8.6 What about TRUNCATE?

Important detail: `TRUNCATE TABLE books;` **does not fire `DELETE` triggers**. `TRUNCATE` is a DDL-like operation that drops and recreates the table — there are no "rows being deleted" from the trigger's point of view.

```sql
TRUNCATE TABLE books;       -- no triggers fire, even if you have DELETE triggers
TRUNCATE TABLE books_archive;  -- archives everything silently — be careful in production!
```

> 🔒 **Production tip:** if your table has important `AFTER DELETE` audit/archive logic, consider **revoking `DROP` and `TRUNCATE` privileges** from your app users. That way deletes can only happen through `DELETE`, which fires triggers.

## 8.7 Quick recap

- `AFTER DELETE` runs **after** a row is successfully removed — and only then.
- `OLD.*` is still available — that's the row that just disappeared.
- Use it to **archive** rows, **log deletions**, or update related tables.
- `TRUNCATE` does **not** fire DELETE triggers — protect your audit logic by restricting that privilege.

---

> **Next:** when you are ready, we'll continue with **Section 9 — Multiple triggers for the same event and time (MySQL 8.0+)**.

---

# Section 9. Multiple triggers for the same event and time

## 9.1 The old rule, and why it changed

Before MySQL 5.7.2, a table could only have **one trigger per event/time combination**. That meant: one `BEFORE INSERT`, one `AFTER INSERT`, one `BEFORE UPDATE`, etc. If you needed two pieces of logic to run on `AFTER INSERT`, you had to **merge them into one trigger** — which got messy fast.

Starting with MySQL **5.7.2** (and fully supported in **8.0+**), MySQL allows **multiple triggers for the same event and time** on a single table. Each trigger is a separate object with its own name.

## 9.2 The new piece: `FOLLOWS` and `PRECEDES`

When you have several triggers for the same event/time, the order they fire in matters. MySQL lets you control that with two clauses:

| Clause | Meaning |
|---|---|
| `FOLLOWS other_trigger_name` | This trigger runs **after** `other_trigger_name`. |
| `PRECEDES other_trigger_name` | This trigger runs **before** `other_trigger_name`. |

If you don't specify either, the trigger is appended to the existing ones in **creation order**.

Example shape:

```sql
CREATE TRIGGER my_trigger
    AFTER INSERT
    ON books
    FOR EACH ROW
    FOLLOWS books_after_insert_create_review
BEGIN
    -- body
END;
```

## 9.3 A real example — two things on `AFTER INSERT`

Suppose we want two separate triggers to fire when a new book is added:

1. **Trigger A** — create a placeholder review row (Section 4).
2. **Trigger B** — also push the new book onto a "notification" table for an email job to pick up.

Both are `AFTER INSERT` on `books`. Both are useful on their own. Let's split them into two triggers instead of one big body.

### Step 1 — Make sure Trigger A exists

```sql
DROP TRIGGER IF EXISTS books_after_insert_create_review;

DELIMITER $$

CREATE TRIGGER books_after_insert_create_review
    AFTER INSERT
    ON books
    FOR EACH ROW
BEGIN
    INSERT INTO book_reviews (book_id, reviewer, rating, comment)
    VALUES (NEW.id, 'pending', NULL, NULL);
END$$

DELIMITER ;
```

### Step 2 — A second small helper table

```sql
DROP TABLE IF EXISTS book_notifications;
CREATE TABLE book_notifications (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    book_id      INT NOT NULL,
    title        VARCHAR(150),
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    sent         TINYINT DEFAULT 0   -- 0 = pending email, 1 = sent
);
```

### Step 3 — Trigger B, explicitly ordered

```sql
DROP TRIGGER IF EXISTS books_after_insert_notify;

DELIMITER $$

CREATE TRIGGER books_after_insert_notify
    AFTER INSERT
    ON books
    FOR EACH ROW
    FOLLOWS books_after_insert_create_review
BEGIN
    INSERT INTO book_notifications (book_id, title)
    VALUES (NEW.id, NEW.title);
END$$

DELIMITER ;
```

Read the `FOLLOWS` line carefully: *"this trigger fires after `books_after_insert_create_review`"*. So the order on a new insert is:

1. `books_after_insert_create_review`  → creates the placeholder review row.
2. `books_after_insert_notify`         → queues a notification.

## 9.4 Try it out

```sql
-- Clear the side tables so the demo is clean
TRUNCATE TABLE book_reviews;
TRUNCATE TABLE book_notifications;

-- One insert
INSERT INTO books (title, author, price, in_stock)
VALUES ('Designing Data-Intensive Applications', 'Martin Kleppmann', 45.00, 6);

-- Both side effects should be visible
SELECT * FROM book_reviews;
-- One row, book_id=<new id>, reviewer='pending'

SELECT * FROM book_notifications;
-- One row, book_id=<new id>, title='Designing Data-Intensive Applications'
```

Two triggers, one `INSERT`, both fired — exactly what we wanted.

## 9.5 Things to keep in mind

| Rule | Why |
|---|---|
| Trigger names must still be unique across the **whole database** | You can drop any trigger by name only — see Section 2.2. |
| A trigger cannot both `FOLLOWS` and `PRECEDES` another trigger | Pick one direction. |
| You can chain: `A FOLLOWS B`, `B FOLLOWS C` | MySQL checks the whole chain when you create/drop a trigger. |
| If two triggers both raise `SIGNAL`, the **first** one wins | The statement is aborted before later triggers run. |
| Order of `OLD.*`/`NEW.*` access is per-row, per-trigger — independent | Each trigger sees the same `OLD`/`NEW` for the row, just at a different moment. |

## 9.6 Quick recap

- MySQL 8.0 (and 5.7.2+) lets you create **multiple triggers per event/time** on a single table.
- Use `FOLLOWS other_trigger` and `PRECEDES other_trigger` to control order.
- Without them, MySQL uses **creation order**.
- Each trigger is still a separate object — `DROP TRIGGER name;` removes just that one.

---

# Section 10. Listing (SHOW) triggers

## 10.1 Why list triggers?

Once you have a few triggers, you forget what they do. MySQL gives you three commands to peek inside:

| Command | What it shows |
|---|---|
| `SHOW TRIGGERS;` | A row per trigger — name, event, table, timing, and a short statement snippet. |
| `SHOW TRIGGERS LIKE 'pattern';` | Same as above, filtered by trigger name pattern. |
| `SHOW CREATE TRIGGER trigger_name;` | The **exact** `CREATE TRIGGER` statement needed to recreate the trigger. |

## 10.2 `SHOW TRIGGERS` — the basics

By default, `SHOW TRIGGERS` lists triggers **in the current database**.

```sql
USE trigger_demo;

SHOW TRIGGERS;
```

You will see one row per trigger with these useful columns:

| Column | What it tells you |
|---|---|
| `Trigger` | The trigger name. |
| `Event`   | `INSERT`, `UPDATE`, or `DELETE`. |
| `Table`   | Which table the trigger watches. |
| `Statement` | The body of the trigger (truncated to ~64 chars). |
| `Timing`  | `BEFORE` or `AFTER`. |
| `Created` | When the trigger was created. |
| `sql_mode`, `Definer`, `character_set_client`, `collation_connection`, `Database Collation` | Environment info at create-time. |

This output is wide — let me show the columns I usually look at first:

```sql
SELECT
    trigger_name,
    event_manipulation  AS event,
    action_timing      AS timing,
    event_object_table AS table_name
FROM information_schema.triggers
WHERE trigger_schema = DATABASE();
```

`information_schema.triggers` is the **standard SQL** way to query triggers — useful for filtering, joining with other tables, or counting.

## 10.3 Filtering by pattern — `LIKE`

You usually don't want *all* triggers — you want the ones for one table or for one event. `LIKE` does pattern matching against the trigger **name**:

```sql
SHOW TRIGGERS LIKE 'books%';
-- All triggers whose name starts with 'books'

SHOW TRIGGERS LIKE '%after_update%';
-- All triggers whose name contains 'after_update'

SHOW TRIGGERS LIKE 'orders\_%';
-- All triggers whose name starts with 'orders_' (escape the underscore)
```

> 💡 `_` in `LIKE` matches **any single character**. To match a literal underscore, escape it with `\_`. MySQL by default treats backslash as the escape character.

A quick recipe for *"show me every trigger on the `books` table"*:

```sql
SELECT *
FROM information_schema.triggers
WHERE event_object_table = 'books'
  AND trigger_schema     = DATABASE();
```

## 10.4 `SHOW CREATE TRIGGER` — get the exact body

`SHOW TRIGGERS` truncates the body. When you need the **full** definition — for example to recreate the trigger on another server — use:

```sql
SHOW CREATE TRIGGER books_after_update_log_price\G
```

The `\G` (in the `mysql` client) prints one column per line, which makes long trigger bodies readable. The output ends with a perfectly valid `CREATE TRIGGER` statement you can copy-paste.

> 📝 **Tip:** copy the output of `SHOW CREATE TRIGGER` **before** you `DROP TRIGGER`. That's the easiest way to "back up" a trigger — MySQL has no `ALTER TRIGGER` and no version-control baked in.

## 10.5 Other ways to inspect triggers

| Where | What you see |
|---|---|
| `SHOW TRIGGERS;` | Short summary, current database |
| `SHOW TRIGGERS FROM my_db;` | Same, but for a specific database |
| `SHOW TRIGGERS LIKE 'pattern';` | Filter by name pattern |
| `SHOW CREATE TRIGGER trigger_name;` | Full `CREATE` statement |
| `SELECT * FROM information_schema.triggers WHERE ...;` | Programmatic access — great for reports |
| `SELECT * FROM mysql.trigger;` | Raw backing table (requires privileges) |

## 10.6 A small housekeeping query

Here's a one-shot query I like to keep in my notes — it prints a tidy summary of every trigger in the current database:

```sql
SELECT
    trigger_name        AS name,
    event_object_table  AS tbl,
    action_timing       AS timing,
    event_manipulation  AS event,
    created
FROM information_schema.triggers
WHERE trigger_schema = DATABASE()
ORDER BY tbl, timing, event, name;
```

Sample output:

| name                                | tbl     | timing  | event   | created            |
|-------------------------------------|---------|---------|---------|--------------------|
| books_after_delete_archive          | books   | AFTER   | DELETE  | 2026-07-05 09:14:22|
| books_after_insert_create_review    | books   | AFTER   | INSERT  | 2026-07-05 09:14:22|
| books_after_insert_notify           | books   | AFTER   | INSERT  | 2026-07-05 09:14:22|
| books_after_update_log_price        | books   | AFTER   | UPDATE  | 2026-07-05 09:14:22|
| books_before_delete_block_in_stock  | books   | BEFORE  | DELETE  | 2026-07-05 09:14:22|
| books_before_insert_trim            | books   | BEFORE  | INSERT  | 2026-07-05 09:14:22|
| books_before_update_validate         | books   | BEFORE  | UPDATE  | 2026-07-05 09:14:22|

That's a quick health-check of your trigger landscape.

## 10.7 Quick recap

- `SHOW TRIGGERS;` — list all triggers in the current database.
- `SHOW TRIGGERS LIKE 'pattern';` — filter by trigger name.
- `SHOW TRIGGERS FROM some_db;` — list triggers in a specific database.
- `SHOW CREATE TRIGGER name;` — print the full `CREATE TRIGGER` statement (use `\G` in the `mysql` client for readability).
- For programmatic access, query `information_schema.triggers` — it's standard SQL.

---

## ✅ Guide recap

| Section | Trigger shape | Typical job |
|---|---|---|
| 3 | `BEFORE INSERT` | Trim / fix / validate new rows; pre-aggregate |
| 4 | `AFTER INSERT`  | Create related rows; push notifications |
| 5 | `BEFORE UPDATE` | Reject or clamp invalid changes |
| 6 | `AFTER UPDATE`  | Audit log; mirror changes elsewhere |
| 7 | `BEFORE DELETE` | Block deletes that break a rule |
| 8 | `AFTER DELETE`  | Archive tombstones; log deletions |
| 9 | Multiple | Split logic into named triggers, control order with `FOLLOWS` / `PRECEDES` |
| 10 | `SHOW TRIGGERS` | Inspect what you have; export `CREATE` statements |

You now have a complete picture of MySQL triggers — from "what is one?" to "list every trigger I have on the `books` table".