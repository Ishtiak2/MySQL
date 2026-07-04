# MySQL Stored Procedures — A Beginner's Guide

A hands-on, section-by-section walkthrough of MySQL stored procedures with simple explanations and runnable examples.

> **How to read this guide:** each sub-section has a short plain-English explanation followed by a small example you can paste into MySQL Workbench, the mysql client, or any GUI.

---

## Table of Contents

- **Section 1. Basic MySQL Stored Procedures**
- **Section 2. Conditional Statements** *(IF, CASE)*
- **Section 3. Loops** *(LOOP, WHILE, REPEAT, LEAVE)*
- **Section 4. Error Handling** *(SHOW WARNINGS/ERRORS, HANDLER, CONDITION, SIGNAL, RESIGNAL)*
- **Section 5. Cursors & Prepared Statements**
- **Section 6. Stored Functions**
- **Section 7. Stored Program Security** *(SQL SECURITY, DEFINER/INVOKER)*
- **Section 8. Transactions in Stored Procedures** *(COMMIT, ROLLBACK, SAVEPOINT, HANDLER)*

For most examples we use a small `classicmodels`-style sample. You can create it like this:

```sql
CREATE DATABASE IF NOT EXISTS sp_demo;
USE sp_demo;

DROP TABLE IF EXISTS products;
CREATE TABLE products (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    stock        INT NOT NULL DEFAULT 0
);

INSERT INTO products (name, price, stock) VALUES
('Notebook',    4.50, 100),
('Pen',         1.20, 500),
('Backpack',   29.99,  25),
('Headphones', 49.00,  10);
```

---

# Section 1. Basic MySQL Stored Procedures

## 1.1 Introduction to MySQL Stored Procedures

**What is it?**
A *stored procedure* is a named block of SQL statements that is **stored inside the database** (not in your application code). You call it by name whenever you need it.

Think of it like a **saved recipe**: you write it once, save it in the database, and "cook" it anytime by calling its name.

**Why use them?**

| Advantages ✅                                | Disadvantages ❌                              |
|----------------------------------------------|-----------------------------------------------|
| Reuse the same SQL in many places            | Harder to debug than app code                 |
| Runs on the server → less data over the wire | Each connection keeps its own copy in memory  |
| Centralized business logic                   | Tighter coupling between DB and app           |
| Better security (grant execute, not tables)  | Portability issues between DB engines         |
| Faster for repeated complex queries          | Versioning/deployment needs care              |

A tiny first look:

```sql
-- A procedure that returns a greeting
DELIMITER $$

CREATE PROCEDURE say_hello()
BEGIN
    SELECT 'Hello from MySQL!' AS message;
END$$

DELIMITER ;

-- Run it
CALL say_hello();
```

---

## 1.2 Changing the Default Delimiter

**Why?**
By default MySQL ends a statement at `;`. But inside a stored procedure you have many statements separated by `;`, and you want MySQL to send the **whole block at once**. So you temporarily change the delimiter to something like `$$` or `//`.

```sql
DELIMITER $$

CREATE PROCEDURE my_proc()
BEGIN
   -- these semicolons are now just statement separators,
   -- NOT the end of the CREATE PROCEDURE command
   SELECT 1;
   SELECT 2;
END$$

DELIMITER ;   -- back to the normal ';' for everything else
```

> Rule of thumb: change the delimiter **before** `CREATE PROCEDURE`, and **restore it** right after the closing `END` symbol.

---

## 1.3 Creating New Stored Procedures

**Syntax:**

```sql
DELIMITER $$

CREATE PROCEDURE procedure_name([parameters])
BEGIN
    -- SQL statements go here
END$$

DELIMITER ;
```

**Example 1 — a procedure that reads from a table:**

```sql
DELIMITER $$

CREATE PROCEDURE get_all_products()
BEGIN
    SELECT id, name, price, stock
    FROM products
    ORDER BY price;
END$$

DELIMITER ;

CALL get_all_products();
```

**Example 2 — a procedure that writes data:**

```sql
DELIMITER $$

CREATE PROCEDURE add_product(
    IN p_name  VARCHAR(100),
    IN p_price DECIMAL(10,2),
    IN p_stock INT
)
BEGIN
    INSERT INTO products (name, price, stock)
    VALUES (p_name, p_price, p_stock);
END$$

DELIMITER ;

CALL add_product('Webcam', 39.99, 15);
SELECT * FROM products WHERE name = 'Webcam';
```

> 💡 If a procedure with the same name already exists, MySQL throws error **1304**. Use `DROP PROCEDURE IF EXISTS ... ; CREATE PROCEDURE ...` (see 1.4).

---

## 1.4 Removing Stored Procedures

Use `DROP PROCEDURE` to permanently delete a procedure.

```sql
-- Drop one procedure
DROP PROCEDURE IF EXISTS say_hello;

-- Drop another
DROP PROCEDURE IF EXISTS get_all_products;
```

* `IF EXISTS` is optional but **recommended** — it avoids an error if the procedure doesn't exist.
* `DROP PROCEDURE` removes the procedure definition only. Tables and data are untouched.

---

## 1.5 Variables

Inside a procedure you can declare **local variables** to hold intermediate values.

**Declare + assign in one step:**

```sql
DELIMITER $$

CREATE PROCEDURE price_with_tax()
BEGIN
    DECLARE tax_rate DECIMAL(5,2) DEFAULT 0.07;  -- 7% tax
    DECLARE base_price DECIMAL(10,2);
    DECLARE final_price DECIMAL(10,2);

    SET base_price = 100.00;
    SET final_price = base_price * (1 + tax_rate);

    SELECT base_price AS base, final_price AS total_with_tax;
END$$

DELIMITER ;

CALL price_with_tax();
```

**Assign a value from a query (`SELECT ... INTO`):**

```sql
DELIMITER $$

CREATE PROCEDURE cheapest_product()
BEGIN
    DECLARE v_name  VARCHAR(100);
    DECLARE v_price DECIMAL(10,2);

    SELECT name, price
      INTO v_name, v_price
      FROM products
     ORDER BY price ASC
     LIMIT 1;

    SELECT v_name AS cheapest, v_price AS price;
END$$

DELIMITER ;

CALL cheapest_product();
```

Variable naming tips:
* Prefix with `v_` (or similar) to avoid confusion with column names.
* Variables exist **only inside** the procedure — they're destroyed when the procedure ends.

---

## 1.6 Parameters (IN, OUT, INOUT)

Parameters let you **pass data in** to a procedure and **get data back** out.

| Mode    | Direction            | Default? |
|---------|----------------------|----------|
| `IN`    | Caller → Procedure   | ✅ Yes    |
| `OUT`   | Procedure → Caller   |          |
| `INOUT` | Caller ↔ Procedure   |          |

### 1.6.1 IN parameter (the most common)

```sql
DELIMITER $$

CREATE PROCEDURE find_products_by_min_price(IN min_price DECIMAL(10,2))
BEGIN
    SELECT name, price
    FROM products
    WHERE price >= min_price
    ORDER BY price;
END$$

DELIMITER ;

CALL find_products_by_min_price(10.00);
```

### 1.6.2 OUT parameter (procedure returns a value)

`OUT` parameters start as `NULL`. The procedure must set them.

```sql
DELIMITER $$

CREATE PROCEDURE get_product_count(OUT total INT)
BEGIN
    SELECT COUNT(*) INTO total FROM products;
END$$

DELIMITER ;

CALL get_product_count(@cnt);
SELECT @cnt AS total_products;
```

### 1.6.3 INOUT parameter (same variable used both ways)

```sql
DELIMITER $$

CREATE PROCEDURE double_value(INOUT x INT)
BEGIN
    SET x = x * 2;
END$$

DELIMITER ;

SET @n = 7;
CALL double_value(@n);
SELECT @n AS doubled;   -- 14
```

> 💡 Always give your caller-side variables the `@` prefix (e.g. `@total`, `@n`) — those are *session variables* that survive across CALLs.

---

## 1.7 Altering a Stored Procedure

MySQL **has no** `ALTER PROCEDURE` statement that changes the body. To change a procedure:

1. **DROP** the old one.
2. **CREATE** the new one.

> MySQL Workbench has a wizard that does exactly this for you — it generates `DROP PROCEDURE IF EXISTS` + `CREATE PROCEDURE`.

```sql
-- Step 1: drop the old version
DROP PROCEDURE IF EXISTS find_products_by_min_price;

-- Step 2: recreate with a new body (now also returning stock)
DELIMITER $$

CREATE PROCEDURE find_products_by_min_price(IN min_price DECIMAL(10,2))
BEGIN
    SELECT name, price, stock
    FROM products
    WHERE price >= min_price
    ORDER BY price;
END$$

DELIMITER ;

CALL find_products_by_min_price(20.00);
```

If you only need to change **metadata** like the comment or SQL security type, MySQL does support a limited `ALTER PROCEDURE` form:

```sql
ALTER PROCEDURE find_products_by_min_price
    COMMENT 'Returns products whose price is >= the given minimum';
```

But for any change inside the body, use **drop + recreate**.

---

## 1.8 Listing Stored Procedures

### From the command line / MySQL Workbench

```sql
-- Show all procedures in the current database
SHOW PROCEDURE STATUS WHERE Db = DATABASE();

-- Show the source / definition of one procedure
SHOW CREATE PROCEDURE get_all_products;
```

### Filter to just the names

```sql
SELECT ROUTINE_NAME, ROUTINE_TYPE, CREATED, LAST_ALTERED
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = DATABASE()
  AND ROUTINE_TYPE   = 'PROCEDURE';
```

* `ROUTINE_TYPE` is `'PROCEDURE'` for procedures and `'FUNCTION'` for stored functions (Section 6).
* `ROUTINE_SCHEMA` is the database name.

### In MySQL Workbench (GUI)

1. Connect to your server.
2. Open the **Navigator** panel → **Schemas** tab.
3. Expand your database → **Stored Procedures**.
4. Right-click a procedure for *Alter Procedure*, *Drop Procedure*, etc.

---

## ✅ Section 1 — Quick Recap

| Sub-section         | One-line takeaway                                                    |
|---------------------|----------------------------------------------------------------------|
| 1.1 Introduction    | Procedures are saved SQL blocks that live inside the database.       |
| 1.2 Delimiter       | Change to `$$` so MySQL doesn't end the `CREATE` early.              |
| 1.3 Creating        | `CREATE PROCEDURE ... BEGIN ... END` and call with `CALL`.           |
| 1.4 Removing        | `DROP PROCEDURE IF EXISTS name;`                                     |
| 1.5 Variables       | `DECLARE ... DEFAULT`; assign with `SET` or `SELECT ... INTO`.       |
| 1.6 Parameters      | `IN` (input), `OUT` (output), `INOUT` (both).                        |
| 1.7 Altering        | Drop + recreate — there is no `ALTER PROCEDURE ... BODY`.            |
| 1.8 Listing         | `SHOW PROCEDURE STATUS` or query `information_schema.ROUTINES`.     |

---


# Section 2. Conditional Statements

Just like any programming language, stored procedures can make decisions. MySQL gives you two ways to branch:

* **`IF ... THEN ... ELSE`** — looks like most languages.
* **`CASE ... WHEN ... THEN`** — looks like a switch statement.

For both, we keep using our `sp_demo.products` table from the top of this guide. Need a refresher?

```sql
USE sp_demo;
SELECT * FROM products;
```

---

## 2.1 The IF statement

**Plain English:** "If condition X is true, do block A; otherwise do block B."

**Syntax:**

```sql
IF condition THEN
    -- statements
ELSEIF another_condition THEN
    -- statements
ELSE
    -- statements
END IF;
```

### Example 2.1.1 — simple IF / ELSE

A procedure that labels a product as **Cheap**, **Mid-range**, or **Premium** based on its price.

```sql
DELIMITER $$

CREATE PROCEDURE label_product(IN p_id INT)
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_label VARCHAR(20);

    SELECT price INTO v_price FROM products WHERE id = p_id;

    IF v_price IS NULL THEN
        SET v_label = 'Unknown product';
    ELSEIF v_price < 5 THEN
        SET v_label = 'Cheap';
    ELSEIF v_price < 25 THEN
        SET v_label = 'Mid-range';
    ELSE
        SET v_label = 'Premium';
    END IF;

    SELECT p_id AS product_id, v_price AS price, v_label AS label;
END$$

DELIMITER ;

CALL label_product(1);   -- Notebook (4.50)  -> Cheap
CALL label_product(4);   -- Headphones (49)  -> Premium
CALL label_product(99);  -- does not exist
```

### Example 2.1.2 — one-liner IF without ELSEIF

When there's only one branch, you can drop the `ELSE`.

```sql
DELIMITER $$

CREATE PROCEDURE warn_if_out_of_stock(IN p_id INT)
BEGIN
    DECLARE v_stock INT;

    SELECT stock INTO v_stock FROM products WHERE id = p_id;

    IF v_stock = 0 THEN
        SELECT 'OUT OF STOCK!' AS warning;
    END IF;
END$$

DELIMITER ;

CALL warn_if_out_of_stock(3);   -- Backpack has stock, no message returned
```

---

## 2.2 The CASE statement

`CASE` has two flavors:

| Flavor | Shape | Use when… |
|---|---|---|
| **Simple CASE** | `CASE value WHEN match THEN ...` | You're comparing **one expression** against several literal values. |
| **Searched CASE** | `CASE WHEN condition THEN ...` | You need **different conditions** per branch (like `IF` / `ELSEIF`). |

Both flavors end with `END CASE;`.

### Example 2.2.1 — simple CASE (compare one value)

Tag the stock level using a simple `CASE`:

```sql
DELIMITER $$

CREATE PROCEDURE stock_status(IN p_id INT)
BEGIN
    DECLARE v_stock INT;
    DECLARE v_status VARCHAR(20);

    SELECT stock INTO v_stock FROM products WHERE id = p_id;

    CASE v_stock
        WHEN 0      THEN SET v_status = 'Out of stock';
        WHEN 1      THEN SET v_status = 'Almost gone';
        WHEN 2      THEN SET v_status = 'Almost gone';
        WHEN 3      THEN SET v_status = 'Almost gone';
        WHEN 100    THEN SET v_status = 'Pile!';
        ELSE             SET v_status = 'In stock';
    END CASE;

    SELECT p_id AS product_id, v_stock AS stock, v_status AS status;
END$$

DELIMITER ;

CALL stock_status(1);   -- 100 -> Pile!
CALL stock_status(2);   -- 500 -> In stock
CALL stock_status(3);   -- 25  -> In stock
```

> 💡 `WHEN 1 THEN ... WHEN 2 THEN ...` means we have to write one `WHEN` per value. To match **a range**, use the searched flavor below.

### Example 2.2.2 — searched CASE (compare conditions)

The searched form is more flexible because each `WHEN` can be its own expression.

```sql
DELIMITER $$

CREATE PROCEDURE stock_band(IN p_id INT)
BEGIN
    DECLARE v_stock INT;
    DECLARE v_band VARCHAR(20);

    SELECT stock INTO v_stock FROM products WHERE id = p_id;

    CASE
        WHEN v_stock IS NULL     THEN SET v_band = 'Unknown product';
        WHEN v_stock = 0         THEN SET v_band = 'Out of stock';
        WHEN v_stock < 10        THEN SET v_band = 'Low';
        WHEN v_stock BETWEEN 10 AND 100 THEN SET v_band = 'Medium';
        ELSE                          SET v_band = 'High';
    END CASE;

    SELECT p_id AS product_id, v_stock AS stock, v_band AS band;
END$$

DELIMITER ;

CALL stock_band(4);   -- 10 stock  -> Medium
CALL stock_band(2);   -- 500 stock -> High
CALL stock_band(3);   -- 25 stock  -> Medium
```

---

## IF vs CASE — which should I use?

| Use `IF ... END IF;` | Use `CASE ... END CASE;` |
|---|---|
| Just one or two branches | Many branches with a single common value to test |
| You want to read it as a flow of conditions | You want a clean, switch-like table of values |

They're equivalent in power; pick whichever you find easier to read.

---

## ✅ Section 2 — Quick Recap

| Sub-section | One-line takeaway |
|---|---|
| 2.1 `IF`        | `IF ... THEN ... ELSEIF ... ELSE ... END IF;` is the standard multi-branch form. |
| 2.2 `CASE`      | Use **simple CASE** for value → branch maps; use **searched CASE** for condition → branch maps. |

---

# 🛠️ Practice Section 2 — Try These Yourself

Below are **5 practice questions**. Each comes with a goal, what to produce, and the answer collapsed in a `<details>` block so you can attempt it first.

> Reminder of the schema you'll keep using:

```sql
USE sp_demo;

DROP TABLE IF EXISTS products;
CREATE TABLE products (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    stock        INT NOT NULL DEFAULT 0
);

INSERT INTO products (name, price, stock) VALUES
('Notebook',    4.50, 100),
('Pen',         1.20, 500),
('Backpack',   29.99,  25),
('Headphones', 49.00,  10);
```

---

### Question 1 — Cheap vs Expensive
**Task.** Write a procedure `price_flag(IN p_id INT, OUT flag VARCHAR(10))` that sets `flag` to `'cheap'` if `price < 10`, `'mid'` if `price < 40`, otherwise `'expensive'`. Use `IF ... ELSEIF ... END IF`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE price_flag(IN p_id INT, OUT flag VARCHAR(10))
BEGIN
    DECLARE v_price DECIMAL(10,2);

    SELECT price INTO v_price FROM products WHERE id = p_id;

    IF v_price IS NULL THEN
        SET flag = 'n/a';
    ELSEIF v_price < 10 THEN
        SET flag = 'cheap';
    ELSEIF v_price < 40 THEN
        SET flag = 'mid';
    ELSE
        SET flag = 'expensive';
    END IF;
END$$

DELIMITER ;

CALL price_flag(1, @f); SELECT @f;
CALL price_flag(4, @f); SELECT @f;
```

</details>

---

### Question 2 — Tiered discount
**Task.** Procedure `apply_discount(IN p_id INT, OUT new_price DECIMAL(10,2))`:
* out of stock → `new_price = -1` (signal a problem)
* `stock < 50`  → 20% off
* `stock < 200` → 10% off
* otherwise    → no discount
Use a **searched CASE**.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE apply_discount(IN p_id INT, OUT new_price DECIMAL(10,2))
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_stock  INT;

    SELECT price, stock INTO v_price, v_stock
    FROM products
    WHERE id = p_id;

    CASE
        WHEN v_stock = 0        THEN SET new_price = -1;
        WHEN v_stock < 50       THEN SET new_price = v_price * 0.80;
        WHEN v_stock < 200      THEN SET new_price = v_price * 0.90;
        ELSE                         SET new_price = v_price;
    END CASE;
END$$

DELIMITER ;

CALL apply_discount(1, @p); SELECT @p AS notebook_after;
CALL apply_discount(3, @p); SELECT @p AS backpack_after;
```

</details>

---

### Question 3 — Day-of-week message
**Task.** Procedure `day_message(IN p_day VARCHAR(10), OUT msg VARCHAR(30))`. Pass one of `'Mon','Tue','Wed','Thu','Fri','Sat','Sun'`; for weekends return `'Happy weekend!'`, for weekdays return `'Back to work!'`, anything else `'Invalid day'`. Use a **simple CASE**.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE day_message(IN p_day VARCHAR(10), OUT msg VARCHAR(30))
BEGIN
    CASE p_day
        WHEN 'Sat' THEN SET msg = 'Happy weekend!';
        WHEN 'Sun' THEN SET msg = 'Happy weekend!';
        WHEN 'Mon' THEN SET msg = 'Back to work!';
        WHEN 'Tue' THEN SET msg = 'Back to work!';
        WHEN 'Wed' THEN SET msg = 'Back to work!';
        WHEN 'Thu' THEN SET msg = 'Back to work!';
        WHEN 'Fri' THEN SET msg = 'Back to work!';
        ELSE            SET msg = 'Invalid day';
    END CASE;
END$$

DELIMITER ;

CALL day_message('Sun', @m); SELECT @m;
CALL day_message('xyz', @m); SELECT @m;
```

</details>

---

### Question 4 — Pass / Fail classifier
**Task.** Procedure `grade_score(IN score INT, OUT grade VARCHAR(2))` using **searched CASE**:
* `score < 0` or `score > 100` → `'INV'`
* `>= 90` → `'A'`
* `>= 75` → `'B'`
* `>= 50` → `'C'`
* otherwise `'F'`

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE grade_score(IN score INT, OUT grade VARCHAR(2))
BEGIN
    CASE
        WHEN score < 0  OR score > 100 THEN SET grade = 'INV';
        WHEN score >= 90               THEN SET grade = 'A';
        WHEN score >= 75               THEN SET grade = 'B';
        WHEN score >= 50               THEN SET grade = 'C';
        ELSE                                SET grade = 'F';
    END CASE;
END$$

DELIMITER ;

CALL grade_score(85, @g); SELECT @g;
CALL grade_score(150, @g); SELECT @g;
CALL grade_score(40, @g); SELECT @g;
```

</details>

---

### Question 5 — Combine IF + CASE
**Task.** Procedure `summarize_product(IN p_id INT)` that, in one call:
1. Uses `IF` to set a local variable `v_label` to `'Famous'` if the product name equals `'Headphones'`, otherwise `'Standard'`.
2. Uses **searched CASE** to set `v_band` based on `price` (Cheap / Mid / Premium with the same thresholds as Example 2.1.1).
3. Returns one `SELECT` with columns `id`, `name`, `price`, `v_label`, `v_band`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE summarize_product(IN p_id INT)
BEGIN
    DECLARE v_name  VARCHAR(100);
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_label VARCHAR(20);
    DECLARE v_band  VARCHAR(20);

    SELECT name, price
      INTO v_name, v_price
      FROM products
     WHERE id = p_id;

    IF v_name = 'Headphones' THEN
        SET v_label = 'Famous';
    ELSE
        SET v_label = 'Standard';
    END IF;

    CASE
        WHEN v_price IS NULL THEN SET v_band = 'Unknown';
        WHEN v_price < 5     THEN SET v_band = 'Cheap';
        WHEN v_price < 25    THEN SET v_band = 'Mid';
        ELSE                      SET v_band = 'Premium';
    END CASE;

    SELECT p_id AS id, v_name AS name, v_price AS price,
           v_label AS label, v_band AS band;
END$$

DELIMITER ;

CALL summarize_product(1);
CALL summarize_product(4);
CALL summarize_product(99);
```

</details>


# Section 3. Loops

Loops let a stored procedure repeat a block of SQL. MySQL has **three** loop forms:

| Loop type | Tests the condition… | Looks like… |
|---|---|---|
| **`WHILE`** | **before** each iteration (skip body if false) | Java/C `while (cond) { … }` |
| **`REPEAT`** | **after** each iteration (run body at least once) | Pascal/do-while `repeat … until cond` |
| **`LOOP`** | **nowhere** — runs forever unless you stop it | an infinite `for(;;)` loop |
| **`LEAVE`** | n/a | `break;` — exit a loop early |
| **`ITERATE`** | n/a | `continue;` — skip to the next iteration |

For loop demos, let's use a tiny helper table (numbers 1..10):

```sql
USE sp_demo;

DROP TABLE IF EXISTS numbers;
CREATE TABLE numbers (n INT PRIMARY KEY);

INSERT INTO numbers (n)
WITH RECURSIVE seq(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 10
)
SELECT n FROM seq;
```

> If your MySQL version doesn't support `WITH RECURSIVE`, insert manually:
> ```sql
> INSERT INTO numbers VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);
> ```

---

## 3.1 WHILE Loop

**Plain English:** "While condition is true, keep running the body."

**Syntax:**

```sql
[label:] WHILE condition DO
    -- statements
END WHILE [label];
```

### Example 3.1.1 — count up to N

```sql
DELIMITER $$

CREATE PROCEDURE count_up(IN p_max INT)
BEGIN
    DECLARE v_i INT DEFAULT 1;

    WHILE v_i <= p_max DO
        SELECT v_i AS n;
        SET v_i = v_i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL count_up(3);   -- returns 1, then 2, then 3 (three result sets)
```

### Example 3.1.2 — fill a new table with running totals

```sql
DELIMITER $$

CREATE PROCEDURE build_running_total()
BEGIN
    DROP TEMPORARY TABLE IF EXISTS running_totals;
    CREATE TEMPORARY TABLE running_totals (
        n        INT,
        cumulative INT
    );

    DECLARE v_i     INT DEFAULT 1;
    DECLARE v_total INT DEFAULT 0;

    WHILE v_i <= 10 DO
        SET v_total = v_total + v_i;
        INSERT INTO running_totals (n, cumulative) VALUES (v_i, v_total);
        SET v_i = v_i + 1;
    END WHILE;

    SELECT * FROM running_totals;
END$$

DELIMITER ;

CALL build_running_total();
```

> ⚠️ MySQL requires `DECLARE` statements to be at the **top** of the `BEGIN ... END` block, before any other statement.

---

## 3.2 REPEAT Loop

**Plain English:** "Run the body; stop when the condition becomes true." The body always runs **at least once**.

**Syntax:**

```sql
[label:] REPEAT
    -- statements
UNTIL condition
END REPEAT [label];
```

Note: `UNTIL` uses the **stop** condition (the opposite of `WHILE`).

### Example 3.2.1 — powers of two

```sql
DELIMITER $$

CREATE PROCEDURE powers_of_two(IN p_max INT)
BEGIN
    DECLARE v_n INT DEFAULT 1;

    DROP TEMPORARY TABLE IF EXISTS powers;
    CREATE TEMPORARY TABLE powers (value INT);

    REPEAT
        INSERT INTO powers VALUES (v_n);
        SET v_n = v_n * 2;
    UNTIL v_n > p_max
    END REPEAT;

    SELECT * FROM powers;
END$$

DELIMITER ;

CALL powers_of_two(100);   -- 1, 2, 4, 8, 16, 32, 64, 128
```

### Example 3.2.2 — pop numbers off a stack (until table is empty)

```sql
DELIMITER $$

CREATE PROCEDURE drain_numbers()
BEGIN
    DECLARE v_n INT;

    REPEAT
        SELECT n INTO v_n FROM numbers ORDER BY n DESC LIMIT 1;
        IF v_n IS NOT NULL THEN
            DELETE FROM numbers WHERE n = v_n;
            SELECT CONCAT('removed ', v_n) AS log;
        END IF;
    UNTIL v_n IS NULL
    END REPEAT;

    SELECT 'all gone' AS done;
END$$

DELIMITER ;

CALL drain_numbers();
SELECT COUNT(*) AS remaining FROM numbers;
```

---

## 3.3 LOOP (basic loop)

**Plain English:** "Run forever until something inside says stop." You pair `LOOP` with `LEAVE` to break out.

**Syntax:**

```sql
[label:] LOOP
    -- statements
END LOOP [label];
```

### Example 3.3.1 — factorial (with LEAVE)

```sql
DELIMITER $$

CREATE PROCEDURE factorial(IN p_n INT, OUT p_result BIGINT)
BEGIN
    DECLARE v_i  INT DEFAULT 1;
    SET p_result = 1;

    my_loop: LOOP
        IF v_i > p_n THEN
            LEAVE my_loop;
        END IF;
        SET p_result = p_result * v_i;
        SET v_i = v_i + 1;
    END LOOP my_loop;
END$$

DELIMITER ;

CALL factorial(5,  @f); SELECT @f;   -- 120
CALL factorial(10, @f); SELECT @f;   -- 3628800
```

The label `my_loop:` is optional but recommended — it makes `LEAVE my_loop` and `ITERATE my_loop` unambiguous when loops are nested.

---

## 3.4 LEAVE statement

**`LEAVE label;`** is the MySQL equivalent of `break`. It immediately exits the labeled block (loop or `BEGIN ... END`).

```sql
DELIMITER $$

CREATE PROCEDURE first_three_in_stock(OUT p_result VARCHAR(200))
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_n   INT;
    DECLARE v_list VARCHAR(200) DEFAULT '';

    DECLARE cur CURSOR FOR SELECT n FROM numbers WHERE n <= 5 ORDER BY n;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_n;
        IF v_done THEN
            LEAVE read_loop;        -- <-- exit early
        END IF;
        IF v_n > 3 THEN
            SET v_done = TRUE;
            LEAVE read_loop;        -- <-- exit early
        END IF;
        SET v_list = CONCAT(v_list, IF(v_list='','',','), v_n);
    END LOOP;
    CLOSE cur;

    SET p_result = v_list;
END$$

DELIMITER ;

CALL first_three_in_stock(@r); SELECT @r;   -- "1,2,3"
```

> Note: `CONTINUE HANDLER` and cursors are covered later (Section 4 and Section 5). For now, just notice that **`LEAVE read_loop;`** is the "break" statement.

---

## 3.5 ITERATE statement (bonus — "continue")

**`ITERATE label;`** skips the rest of the current iteration and jumps to the **next** loop pass. Like `continue` in C/Java.

```sql
DELIMITER $$

CREATE PROCEDURE print_odds(IN p_max INT)
BEGIN
    DECLARE v_i INT DEFAULT 0;

    odds: WHILE v_i < p_max DO
        SET v_i = v_i + 1;
        IF v_i % 2 = 0 THEN
            ITERATE odds;           -- skip even numbers
        END IF;
        SELECT v_i AS odd_number;
    END WHILE odds;
END$$

DELIMITER ;

CALL print_odds(7);   -- returns 1, 3, 5, 7
```

---

## WHILE vs REPEAT vs LOOP — quick comparison

| Feature | `WHILE` | `REPEAT` | bare `LOOP` |
|---|---|---|---|
| Tests condition | **before** | **after** | never |
| Body runs at least once? | No | **Yes** | Yes |
| Stops how? | condition becomes false | condition becomes true | must `LEAVE` |
| Best for | "do this N times" when 0 is allowed | "do this at least once, then check" | custom loop with multiple exit points |

---

## ✅ Section 3 — Quick Recap

| Sub-section | One-line takeaway |
|---|---|
| 3.1 `WHILE`  | `WHILE cond DO ... END WHILE;` — condition checked first. |
| 3.2 `REPEAT` | `REPEAT ... UNTIL cond END REPEAT;` — body runs at least once. |
| 3.3 `LOOP`   | Bare `LOOP` never stops on its own; pair it with `LEAVE`. |
| 3.4 `LEAVE`  | `LEAVE label;` = `break;` — exits the labeled loop. |
| 3.5 `ITERATE`| `ITERATE label;` = `continue;` — jumps to the next iteration. |

---

# 🛠️ Practice Section 3 — Try These Yourself

Below are **5 practice questions** on loops. Solutions are in collapsed `<details>` blocks.

> Setup (re-use the `numbers` table from the start of Section 3):
>
> ```sql
> USE sp_demo;
> SELECT * FROM numbers;
> ```

---

### Question 1 — Sum of 1..N (WHILE)
**Task.** Procedure `sum_to_n(IN p_n INT, OUT p_sum BIGINT)` using **`WHILE`** that computes `1 + 2 + ... + p_n`. Call it with `p_n = 100` and verify the result is `5050`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE sum_to_n(IN p_n INT, OUT p_sum BIGINT)
BEGIN
    DECLARE v_i INT DEFAULT 1;
    SET p_sum = 0;

    WHILE v_i <= p_n DO
        SET p_sum = p_sum + v_i;
        SET v_i   = v_i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL sum_to_n(100, @s); SELECT @s;   -- 5050
```

</details>

---

### Question 2 — Count digits (REPEAT)
**Task.** Procedure `digit_count(IN p_n INT, OUT p_count INT)` using **`REPEAT`** that counts how many digits are in `p_n` (assume `p_n > 0`). Example: `digit_count(12345)` → `5`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE digit_count(IN p_n INT, OUT p_count INT)
BEGIN
    DECLARE v_x INT;
    SET p_count = 0;
    SET v_x     = p_n;

    REPEAT
        SET p_count = p_count + 1;
        SET v_x     = FLOOR(v_x / 10);
    UNTIL v_x = 0
    END REPEAT;
END$$

DELIMITER ;

CALL digit_count(12345, @c); SELECT @c;   -- 5
CALL digit_count(7,     @c); SELECT @c;   -- 1
```

</details>

---

### Question 3 — Find first match (LOOP + LEAVE)
**Task.** Procedure `first_n_greater(IN p_threshold INT, OUT p_result INT)` that scans the `numbers` table in ascending order and returns (via `OUT`) the **first** `n` strictly greater than `p_threshold`. Use a **`LOOP`** with **`LEAVE`**. If no such value exists, return `-1`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE first_n_greater(IN p_threshold INT, OUT p_result INT)
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_n    INT;

    DECLARE cur CURSOR FOR
        SELECT n FROM numbers WHERE n > p_threshold ORDER BY n ASC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET p_result = -1;

    OPEN cur;
    scan: LOOP
        FETCH cur INTO v_n;
        IF v_done THEN
            LEAVE scan;
        END IF;
        SET p_result = v_n;
        LEAVE scan;                   -- we only want the first one
    END LOOP scan;
    CLOSE cur;
END$$

DELIMITER ;

CALL first_n_greater(7,  @r); SELECT @r;   -- 8
CALL first_n_greater(100, @r); SELECT @r;   -- -1
```

</details>

---

### Question 4 — Skip multiples (ITERATE)
**Task.** Procedure `print_not_multiples_of(IN p_k INT, IN p_max INT)` that prints every integer from `1` to `p_max` that is **not** a multiple of `p_k`. Use a **`WHILE`** loop plus **`ITERATE`** to skip the multiples. Example: `print_not_multiples_of(3, 10)` should print `1, 2, 4, 5, 7, 8, 10`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE print_not_multiples_of(IN p_k INT, IN p_max INT)
BEGIN
    DECLARE v_i INT DEFAULT 0;

    walk: WHILE v_i < p_max DO
        SET v_i = v_i + 1;
        IF v_i MOD p_k = 0 THEN
            ITERATE walk;             -- skip multiples of p_k
        END IF;
        SELECT v_i AS value;
    END WHILE walk;
END$$

DELIMITER ;

CALL print_not_multiples_of(3, 10);
```

</details>

---

### Question 5 — Build a comma-separated string
**Task.** Procedure `concat_numbers_under(IN p_max INT, OUT p_csv VARCHAR(200))` that, using any loop style you like, builds a comma-separated string of every `n` in the `numbers` table that is `< p_max`. Example: `concat_numbers_under(6, @c)` → `'1,2,3,4,5'`. Tip: clear the output first (`SET p_csv = '';`) and use `CONCAT(p_csv, IF(p_csv='','',','), v_n)`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE concat_numbers_under(IN p_max INT, OUT p_csv VARCHAR(200))
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_n    INT;

    DECLARE cur CURSOR FOR
        SELECT n FROM numbers WHERE n < p_max ORDER BY n ASC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET p_csv = '';

    OPEN cur;
    build: LOOP
        FETCH cur INTO v_n;
        IF v_done THEN
            LEAVE build;
        END IF;
        SET p_csv = CONCAT(p_csv, IF(p_csv = '', '', ','), v_n);
    END LOOP build;
    CLOSE cur;
END$$

DELIMITER ;

CALL concat_numbers_under(6, @c); SELECT @c;   -- "1,2,3,4,5"
```

</details>


# Section 4. Error Handling

Sooner or later, a procedure will hit an error — bad input, a missing row, a duplicate key. Without error handling, the procedure **aborts immediately**, leaving your work half-done. With error handling you can:

* catch specific errors and continue,
* roll back changes,
* raise your own clear error messages with `SIGNAL`,
* re-raise the original error after doing clean-up work with `RESIGNAL`.

---

## 4.1 SHOW WARNINGS

**Plain English:** "Show me the **warnings** from the most recent statement." Warnings are non-fatal notes — usually "this is unusual, but I did the best I could."

```sql
-- Force a string → integer truncation warning, then inspect it
SELECT CAST('abc' AS UNSIGNED);   -- 0  (with warning)

SHOW WARNINGS;
```

`SHOW WARNINGS` returns a 3-column result: `Level`, `Code`, `Message`.

```sql
-- Common warning codes
-- 1265  Data truncated for column ...
-- 1366  Incorrect integer value: 'abc' for column ...
-- 1048  Column '...' cannot be null      (sometimes a warning, sometimes an error)
```

> 💡 Diagnostics can also be turned on per-session:
>
> ```sql
> SET SESSION sql_notes = 0;    -- quiet "Note" messages
> SET SESSION sql_notes = 1;    -- turn them back on
> ```
>
> Note: `SHOW WARNINGS` only shows what *that same connection* produced and **resets after the next statement**.

---

## 4.2 SHOW ERRORS

**`SHOW ERRORS`** shows the **errors** from the most recent statement. Like warnings, but only fatal ones (and only for the connection that ran the statement).

```sql
SELECT 'x' INTO @x;
SHOW ERRORS;
-- After error 1324 (Undeclared variable: @y)

SELECT n FROM nonexistent_db.numbers;
SHOW ERRORS;
-- After error 1146 (Table doesn't exist)
```

You can limit both to a small fixed count:
```sql
SHOW WARNINGS LIMIT 1;
SHOW ERRORS   LIMIT 1;
```

---

## 4.3 DECLARE ... HANDLER

A **handler** is the cleanest way to react to errors/warnings **inside** a stored procedure. Think of it as a `try/catch` block.

**Syntax:**

```sql
DECLARE handler_action HANDLER
    FOR condition_value [, condition_value] ...
    handler_statement;
```

| Part              | Meaning                                                                 |
|-------------------|-------------------------------------------------------------------------|
| `handler_action`  | `CONTINUE` (keep running) or `EXIT` (leave the procedure)                |
| `condition_value` | One of: `SQLSTATE [VALUE] '5xxxxx'`, `Mysql error number`, `SQLWARNING`, `NOT FOUND`, `SQLEXCEPTION` |
| `handler_statement` | A single statement, often `SET done = TRUE;` |

### Example 4.3.1 — handle a "row not found" the gentle way

```sql
DELIMITER $$

CREATE PROCEDURE find_by_id(IN p_id INT)
BEGIN
    DECLARE v_name VARCHAR(100);

    -- When SELECT ... INTO returns nothing, set v_name to NULL
    -- instead of error 1325 (No data) or 1324 (Undeclared...)
    SELECT name INTO v_name FROM products WHERE id = p_id;

    SELECT IFNULL(v_name, 'NOT FOUND') AS name;
END$$

DELIMITER ;

CALL find_by_id(1);    -- Notebook
CALL find_by_id(99);   -- NOT FOUND
```

### Example 4.3.2 — continue handler (skip the bad row)

```sql
DELIMITER $$

CREATE PROCEDURE average_price_above(IN min_price DECIMAL(10,2))
BEGIN
    DECLARE v_sum   DECIMAL(10,2) DEFAULT 0;
    DECLARE v_count INT           DEFAULT 0;
    DECLARE v_done  INT           DEFAULT FALSE;
    DECLARE v_n     VARCHAR(100);
    DECLARE v_p     DECIMAL(10,2);

    DECLARE cur CURSOR FOR
        SELECT name, price FROM products WHERE price >= min_price;

    -- 1325 = "No data – zero rows fetched, updated, or deleted"
    -- '02000' is the matching SQLSTATE for the same condition.
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur;
    read: LOOP
        FETCH cur INTO v_n, v_p;
        IF v_done THEN
            LEAVE read;
        END IF;
        SET v_sum   = v_sum + v_p;
        SET v_count = v_count + 1;
    END LOOP read;
    CLOSE cur;

    SELECT v_count       AS rows_used,
           v_sum         AS sum_prices,
           v_sum / NULLIF(v_count, 0) AS average_price;
END$$

DELIMITER ;

CALL average_price_above(10);   -- skips the cheap ones
```

### Example 4.3.3 — exit handler (abort on error)

```sql
DELIMITER $$

CREATE PROCEDURE safe_insert(IN p_name VARCHAR(100), IN p_price DECIMAL(10,2))
BEGIN
    -- 1062 = Duplicate entry for a UNIQUE key
    DECLARE EXIT HANDLER FOR 1062
        SELECT CONCAT('Product "', p_name, '" already exists!') AS error;

    INSERT INTO products (name, price) VALUES (p_name, p_price);
    SELECT CONCAT('Inserted ', p_name) AS ok;
END$$

DELIMITER ;

CALL safe_insert('Mouse', 12.50);   -- Inserted Mouse
CALL safe_insert('Mouse', 12.50);   -- already exists! (handler fired)
```

### Example 4.3.4 — handler for any `SQLEXCEPTION`

```sql
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    ROLLBACK;             -- (we'll talk about transactions in Section 8)
    RESIGNAL;             -- <-- see 4.6
END;
```

---

## 4.4 DECLARE ... CONDITION

A **condition** is just a *name* you give to a particular MySQL error code or SQLSTATE. Useful when:

* the same code is referenced in multiple handlers,
* you want to **raise** it later with `SIGNAL` (see 4.5).

**Syntax:**

```sql
DECLARE condition_name CONDITION FOR { SQLSTATE [VALUE] '5xxxxx' | mysql_error_code };
```

### Example 4.4.1 — name error 1062

```sql
DELIMITER $$

CREATE PROCEDURE safe_insert_named(IN p_name VARCHAR(100), IN p_price DECIMAL(10,2))
BEGIN
    DECLARE duplicate_key CONDITION FOR 1062;

    DECLARE EXIT HANDLER FOR duplicate_key
        SELECT CONCAT(p_name, ' already exists (via named condition)') AS msg;

    INSERT INTO products (name, price) VALUES (p_name, p_price);
    SELECT CONCAT('Inserted ', p_name) AS ok;
END$$

DELIMITER ;

CALL safe_insert_named('Keyboard', 25.00);
CALL safe_insert_named('Keyboard', 25.00);
```

### Example 4.4.2 — name a SQLSTATE

```sql
DECLARE out_of_range CONDITION FOR SQLSTATE '45000';
DECLARE EXIT HANDLER FOR out_of_range
    SELECT 'Out of range!' AS msg;
```

`45000` is the standard SQLSTATE for "user-defined error" — used heavily by `SIGNAL`.

---

## 4.5 SIGNAL

**`SIGNAL`** is how you raise your own error from inside a procedure. Compared to silently `SELECT`-ing a message, `SIGNAL` actually **aborts** the call and propagates to the caller.

**Syntax:**

```sql
SIGNAL SQLSTATE { VALUE '45000' | sqlstate_literal }
    SET MESSAGE_TEXT  = 'your message here',
        MYSQL_ERRNO   = <number>,    -- optional
        SCHEMA_NAME   = '...',       -- optional
        TABLE_NAME    = '...'        -- optional
;
```

### Example 4.5.1 — minimum usage

```sql
DELIMITER $$

CREATE PROCEDURE divide_check(IN a INT, IN b INT)
BEGIN
    IF b = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Division by zero is not allowed';
    END IF;

    SELECT a / b AS result;
END$$

DELIMITER ;

CALL divide_check(10, 2);   -- 5
CALL divide_check(10, 0);   -- ERROR 1644: Division by zero is not allowed
```

### Example 4.5.2 — `SIGNAL` + a named condition

```sql
DELIMITER $$

CREATE PROCEDURE raise_only_adults(IN p_age INT)
BEGIN
    DECLARE too_young CONDITION FOR SQLSTATE '45000';

    IF p_age < 18 THEN
        SIGNAL too_young
            SET MESSAGE_TEXT = 'Age must be 18 or older',
                MYSQL_ERRNO  = 5001;
    END IF;

    SELECT 'Welcome!' AS greeting;
END$$

DELIMITER ;

CALL raise_only_adults(21);   -- Welcome!
CALL raise_only_adults(15);   -- ERROR 5001: Age must be 18 or older
```

### Example 4.5.3 — signal within a handler

```sql
DELIMITER $$

CREATE PROCEDURE report_duplicate()
BEGIN
    DECLARE EXIT HANDLER FOR 1062
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Could not insert duplicate row',
                MYSQL_ERRNO  = 9999;

    INSERT INTO products (id, name, price) VALUES (1, 'Dup', 1.00);
END$$

DELIMITER ;

CALL report_duplicate();   -- raises MYSQL_ERRNO = 9999
```

---

## 4.6 RESIGNAL

`RESIGNAL` is `SIGNAL`'s sister: it **re-raises the current error** instead of inventing a new one. Use it inside a handler when you want to **log/clean up first** but still propagate the failure to the caller.

### Example 4.6.1 — log then resignal

```sql
DROP TABLE IF EXISTS error_log;
CREATE TABLE error_log (
    id    INT PRIMARY KEY AUTO_INCREMENT,
    when_ DATETIME DEFAULT CURRENT_TIMESTAMP,
    who   VARCHAR(100),
    msg   VARCHAR(500)
);

DELIMITER $$

CREATE PROCEDURE risky_insert(IN p_name VARCHAR(100))
BEGIN
    -- If anything goes wrong, log it AND let the caller see the original error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO error_log (who, msg)
        VALUES (CURRENT_USER(), 'Failed while inserting');
        RESIGNAL;   -- <-- raise the original error again
    END;

    INSERT INTO products (id, name, price) VALUES (NULL, p_name, NULL);
END$$

DELIMITER ;

CALL risky_insert('oops');   -- fails because price is NOT NULL; logged; resignaled
SELECT * FROM error_log;
```

### Example 4.6.2 — change the error message then resignal

```sql
DECLARE CONTINUE HANDLER FOR 1062
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Friendly message for the user';

    -- ^ that swallows the duplicate entry error;
    --   if you'd rather KEEP the original error but with a friendlier message:
    RESIGNAL SET MESSAGE_TEXT = 'Friendly wrapper around the duplicate-key error';
END;
```

> Use **`RESIGNAL`** when the **original error info** (code + message + state) matters to the caller; use **`SIGNAL`** when you want to invent a brand-new error.

---

## Quick reference card

| Statement                       | Purpose                                                |
|---------------------------------|--------------------------------------------------------|
| `SHOW WARNINGS`                 | See warnings produced by the previous statement.       |
| `SHOW ERRORS`                   | See errors produced by the previous statement.         |
| `DECLARE ... HANDLER FOR ...`   | `try/catch` block for one or more conditions.          |
| `DECLARE name CONDITION FOR ...`| Label a MySQL error code / SQLSTATE for reuse.         |
| `SIGNAL SQLSTATE '45000' ...`   | Raise a brand-new error from your procedure.           |
| `RESIGNAL`                      | Re-raise the *current* error (often inside a handler). |

---

## ✅ Section 4 — Quick Recap

| Sub-section                  | One-line takeaway                                                       |
|------------------------------|-------------------------------------------------------------------------|
| 4.1 `SHOW WARNINGS`          | `SHOW WARNINGS;` shows non-fatal notices from the previous statement.   |
| 4.2 `SHOW ERRORS`            | `SHOW ERRORS;` shows fatal errors from the previous statement.          |
| 4.3 `DECLARE … HANDLER`      | `CONTINUE` keeps going, `EXIT` aborts. Fires on a code/SQLSTATE/keyword. |
| 4.4 `DECLARE … CONDITION`    | Name a code/SQLSTATE for reuse in handlers or `SIGNAL`.                 |
| 4.5 `SIGNAL`                 | Raise your own error: `SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=...`.  |
| 4.6 `RESIGNAL`               | Re-raise the active error, optionally changing the message.             |

---

# 🛠️ Practice Section 4 — Try These Yourself

> Reminder of the table you'll work with:
>
> ```sql
> USE sp_demo;
> SELECT * FROM products;
> -- id  name       price  stock
> -- 1   Notebook    4.50  100
> -- 2   Pen         1.20  500
> -- 3   Backpack   29.99   25
> -- 4   Headphones 49.00   10
> ```

---

### Question 1 — Diagnose with SHOW WARNINGS
**Task.** Run `SELECT CAST('xyz' AS UNSIGNED);` and then call `SHOW WARNINGS;`. In your answer, note **the level**, **the error code**, and **the message**. (Truncation/conversion warnings have codes **1264** or **1366**.)

<details>
<summary>Show expected output</summary>

```
mysql> SELECT CAST('xyz' AS UNSIGNED);
+----------------------------+
| CAST('xyz' AS UNSIGNED)    |
+----------------------------+
|                          0 |
+----------------------------+
1 row in set, 1 warning (0.00 sec)

mysql> SHOW WARNINGS;
+---------+------+---------------------------------------------------------------+
| Level   | Code | Message                                                       |
+---------+------+---------------------------------------------------------------+
| Warning | 1366 | Incorrect integer value: 'xyz' for column '...' at row 1      |
+---------+------+---------------------------------------------------------------+
```

</details>

---

### Question 2 — CONTINUE handler for NOT FOUND
**Task.** Procedure `get_product_name(IN p_id INT, OUT p_name VARCHAR(100))`. Use a `SELECT ... INTO` plus a **`CONTINUE HANDLER FOR NOT FOUND`** to set `p_name = 'NOT FOUND'` instead of erroring. Test with `p_id = 1` and `p_id = 999`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE get_product_name(IN p_id INT, OUT p_name VARCHAR(100))
BEGIN
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET p_name = 'NOT FOUND';

    -- initialise in case handler does NOT fire
    SET p_name = 'NOT FOUND';

    SELECT name INTO p_name
    FROM products
    WHERE id = p_id;
END$$

DELIMITER ;

CALL get_product_name(1,   @n); SELECT @n;   -- Notebook
CALL get_product_name(999, @n); SELECT @n;   -- NOT FOUND
```

</details>

---

### Question 3 — EXIT handler for duplicate key
**Task.** Procedure `add_product_safe(IN p_name VARCHAR(100), IN p_price DECIMAL(10,2))`. Use a **`DECLARE … CONDITION`** to name error 1062, then an **`EXIT HANDLER`** for that condition that returns a friendly message via `SELECT`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE add_product_safe(
    IN p_name  VARCHAR(100),
    IN p_price DECIMAL(10,2)
)
BEGIN
    DECLARE duplicate_name CONDITION FOR 1062;

    DECLARE EXIT HANDLER FOR duplicate_name
        SELECT CONCAT('Duplicate product: ', p_name) AS error;

    -- To exercise the handler, give the table a UNIQUE constraint
    -- on name first (outside the procedure):
    -- ALTER TABLE products ADD UNIQUE KEY ux_name (name);

    INSERT INTO products (name, price) VALUES (p_name, p_price);
    SELECT CONCAT('Inserted ', p_name) AS ok;
END$$

DELIMITER ;

CALL add_product_safe('Mouse',    12.50);
CALL add_product_safe('Mouse',    12.50);   -- duplicate error path
```

</details>

---

### Question 4 — `SIGNAL` for bad input
**Task.** Procedure `update_price(IN p_id INT, IN p_new_price DECIMAL(10,2))`. If `p_new_price <= 0`, raise `SIGNAL SQLSTATE '45000'` with `MESSAGE_TEXT = 'Price must be positive'` and `MYSQL_ERRNO = 5200`. Otherwise run the `UPDATE`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE update_price(
    IN p_id        INT,
    IN p_new_price DECIMAL(10,2)
)
BEGIN
    IF p_new_price <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Price must be positive',
                  MYSQL_ERRNO  = 5200;
    END IF;

    UPDATE products SET price = p_new_price WHERE id = p_id;
    SELECT CONCAT('Updated id ', p_id) AS done;
END$$

DELIMITER ;

CALL update_price(1,  5.00);   -- Updated id 1
CALL update_price(1, -1.00);   -- ERROR 5200: Price must be positive
```

</details>

---

### Question 5 — `RESIGNAL` after logging
**Task.** Create table `error_log(id INT AUTO_INCREMENT PK, msg VARCHAR(255))`. Procedure `dangerous_update(IN p_name VARCHAR(100), IN p_new_price DECIMAL(10,2))` does:
1. `DECLARE EXIT HANDLER FOR SQLEXCEPTION` that **inserts** into `error_log` with a message and then **calls `RESIGNAL;`** to re-raise the original error.
2. Runs an `UPDATE products SET price = p_new_price WHERE name = p_name`.

Try updating a non-existent product name — you should see an error from the caller AND a row in `error_log`.

<details>
<summary>Show solution</summary>

```sql
DROP TABLE IF EXISTS error_log;
CREATE TABLE error_log (
    id  INT PRIMARY KEY AUTO_INCREMENT,
    msg VARCHAR(255)
);

DELIMITER $$

CREATE PROCEDURE dangerous_update(
    IN p_name       VARCHAR(100),
    IN p_new_price  DECIMAL(10,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO error_log (msg)
        VALUES (CONCAT('Failed update for ', p_name));
        RESIGNAL;    -- re-raise the original error
    END;

    UPDATE products
       SET price = p_new_price
     WHERE name  = p_name;
END$$

DELIMITER ;

CALL dangerous_update('NoSuchProduct', 9.99);
-- ERROR 0 ... (SQL warning), plus:
SELECT * FROM error_log;
```

</details>


# Section 5. Cursors & Prepared Statements

Sometimes your procedure needs to walk a result set **row by row** (a cursor), or run a parameter-dependent statement repeatedly **without reparsing it** (a prepared statement). This section covers both.

---

## 5.1 Cursors

A **cursor** lets you iterate over a `SELECT` result set inside a stored procedure — one row at a time. Think of it as a "result-set iterator."

**Cursor lifecycle:**

| Step     | Statement                          | Purpose                                                |
|----------|------------------------------------|--------------------------------------------------------|
| 1. Declare | `DECLARE cur CURSOR FOR <SELECT>;`| Define the `SELECT` the cursor will walk.              |
| 2. Declare | `DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;` | Detect that the cursor is exhausted. |
| 3. Open   | `OPEN cur;`                        | Run the SELECT, create the result set on the server.   |
| 4. Fetch  | `FETCH cur INTO v1, v2, ...;`     | Get the next row's columns into local variables.       |
| 5. Close  | `CLOSE cur;`                       | Free the server-side result set.                       |

> ⚠️ Cursor rules in MySQL:
> * The cursor `DECLARE` must come **after** all `DECLARE` for variables, but **before** the `DECLARE … HANDLER`.
> * The columns in `FETCH … INTO` must match — same number, compatible types.
> * Only **forward-only, read-only** cursors are supported in stored procedures (no scroll backwards).
> * Cursors are **server-side** — they don't ship the whole result to the client.

### Example 5.1.1 — print every product

```sql
DELIMITER $$

CREATE PROCEDURE list_products()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id   INT;
    DECLARE v_name VARCHAR(100);
    DECLARE v_price DECIMAL(10,2);

    DECLARE cur CURSOR FOR
        SELECT id, name, price FROM products ORDER BY id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur;
    walk: LOOP
        FETCH cur INTO v_id, v_name, v_price;
        IF v_done THEN
            LEAVE walk;
        END IF;
        SELECT v_id AS id, v_name AS name, v_price AS price;
    END LOOP walk;
    CLOSE cur;
END$$

DELIMITER ;

CALL list_products();
```

### Example 5.1.2 — build a comma-separated string of names

```sql
DELIMITER $$

CREATE PROCEDURE names_csv(OUT p_list VARCHAR(4000))
BEGIN
    DECLARE v_done  INT DEFAULT FALSE;
    DECLARE v_name  VARCHAR(100);
    DECLARE v_first INT DEFAULT TRUE;

    DECLARE cur CURSOR FOR SELECT name FROM products ORDER BY id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET p_list = '';

    OPEN cur;
    walk: LOOP
        FETCH cur INTO v_name;
        IF v_done THEN
            LEAVE walk;
        END IF;
        IF v_first THEN
            SET p_list = v_name;
            SET v_first = FALSE;
        ELSE
            SET p_list = CONCAT(p_list, ',', v_name);
        END IF;
    END LOOP walk;
    CLOSE cur;
END$$

DELIMITER ;

CALL names_csv(@list); SELECT @list;
```

### Example 5.1.3 — cursor that calculates a running total

```sql
DELIMITER $$

CREATE PROCEDURE reorder_report(IN p_threshold INT)
BEGIN
    -- Products with stock < p_threshold, listed with their suggested re-order qty.
    DECLARE v_done   INT DEFAULT FALSE;
    DECLARE v_id     INT;
    DECLARE v_name   VARCHAR(100);
    DECLARE v_stock  INT;
    DECLARE v_reorder INT;

    DROP TEMPORARY TABLE IF EXISTS reorder_list;
    CREATE TEMPORARY TABLE reorder_list (
        id        INT,
        name      VARCHAR(100),
        stock     INT,
        reorder_to INT
    );

    DECLARE cur CURSOR FOR
        SELECT id, name, stock FROM products
        WHERE stock < p_threshold
        ORDER BY stock ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur;
    fill: LOOP
        FETCH cur INTO v_id, v_name, v_stock;
        IF v_done THEN
            LEAVE fill;
        END IF;
        SET v_reorder = GREATEST(100 - v_stock, 0);
        INSERT INTO reorder_list VALUES (v_id, v_name, v_stock, v_reorder);
    END LOOP fill;
    CLOSE cur;

    SELECT * FROM reorder_list ORDER BY stock;
END$$

DELIMITER ;

CALL reorder_report(50);
```

### Example 5.1.4 — nested cursors (orders + items)

```sql
-- Helper tables (one-to-many)
DROP TABLE IF EXISTS orders, order_items;
CREATE TABLE orders     (id INT PRIMARY KEY, customer VARCHAR(50));
CREATE TABLE order_items(order_id INT, product_id INT, qty INT);

INSERT INTO orders VALUES
 (1,'Alice'), (2,'Bob');

INSERT INTO order_items VALUES
 (1,1,2), (1,2,5),     -- Alice: 2 notebooks + 5 pens
 (2,4,1);              -- Bob:   1 headphones

DELIMITER $$

CREATE PROCEDURE order_totals()
BEGIN
    DECLARE v_done_o INT DEFAULT FALSE;
    DECLARE v_o_id   INT;
    DECLARE v_cust   VARCHAR(50);

    DECLARE v_done_i INT DEFAULT FALSE;
    DECLARE v_p_id   INT;
    DECLARE v_qty    INT;
    DECLARE v_price  DECIMAL(10,2);
    DECLARE v_total  DECIMAL(12,2);

    DECLARE cur_orders CURSOR FOR SELECT id, customer FROM orders ORDER BY id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done_o = TRUE;

    OPEN cur_orders;
    o_loop: LOOP
        FETCH cur_orders INTO v_o_id, v_cust;
        IF v_done_o THEN LEAVE o_loop; END IF;

        SET v_total = 0;
        SET v_done_i = FALSE;

        BEGIN
            DECLARE cur_items CURSOR FOR
                SELECT product_id, qty FROM order_items WHERE order_id = v_o_id;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done_i = TRUE;

            OPEN cur_items;
            i_loop: LOOP
                FETCH cur_items INTO v_p_id, v_qty;
                IF v_done_i THEN LEAVE i_loop; END IF;

                SELECT price INTO v_price FROM products WHERE id = v_p_id;
                SET v_total = v_total + IFNULL(v_price,0) * v_qty;
            END LOOP i_loop;
            CLOSE cur_items;
        END;

        SELECT v_o_id AS order_id, v_cust AS customer, v_total AS total;
    END LOOP o_loop;
    CLOSE cur_orders;
END$$

DELIMITER ;

CALL order_totals();
```

> Notice the **inner `BEGIN … END` block**. MySQL requires every `DECLARE` inside a block to live in its own scope — nesting cursors without an inner block triggers error **1321 *Function or expression contains a cursor declaration that is not allowed in this context***.

---

## When NOT to use cursors

Cursors are slow because MySQL iterates row-by-row instead of doing set-based work. Avoid them when:

* the same job can be done with one `UPDATE` / `INSERT … SELECT` / aggregate function;
* you're moving large amounts of data (millions of rows).

Rule of thumb: if you can express it as a single statement, don't open a cursor.

---

## 5.2 Prepared Statements

A **prepared statement** is a SQL template you parse once and run many times with different parameter values. MySQL's stored-procedure API mirrors what you write in JDBC / `mysqli` / PDO.

**Syntax:**

```sql
PREPARE stmt_name FROM 'SELECT ... WHERE id = ?';

-- pass the value (only constants / user variables / local vars are allowed here)
SET @id := 42;
EXECUTE stmt_name USING @id;

-- free server-side resources
DEALLOCATE PREPARE stmt_name;
```

> The `?` placeholders can only appear where MySQL expects a **data value** — not table or column names. Same rule as bound parameters in any other language.

### Why prepared statements matter

1. **Safety.** The parameter value is never spliced into the SQL string, so SQL-injection attacks are not possible even if the user submits `' OR 1=1 --`.
2. **Speed.** The server parses/prepares the SQL once. Every `EXECUTE` only ships parameter values, so roundtrips are smaller and the optimizer can cache the plan (less so for stored-proc prepared statements, but the API is identical).

### Example 5.2.1 — session-level prepared statement

```sql
PREPARE q FROM 'SELECT id, name, price FROM products WHERE price > ?';

SET @min := 10;
EXECUTE q USING @min;

SET @min := 30;
EXECUTE q USING @min;

DEALLOCATE PREPARE q;
```

### Example 5.2.2 — inside a stored procedure

Inside a procedure the syntax is the **same** as at session level, but you must keep names in scope of the current block.

```sql
DELIMITER $$

CREATE PROCEDURE get_products_above(IN p_min DECIMAL(10,2))
BEGIN
    -- Prepared statements in stored programs must NOT clash with other
    -- statements or user variables; pick a clear name.
    PREPARE stmt FROM 'SELECT id, name, price
                       FROM products
                       WHERE price > ?
                       ORDER BY price';

    EXECUTE stmt USING p_min;        -- <-- IN parameter works as a USAGE target
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;

CALL get_products_above(20);
```

> ⚠️ Beginning in **MySQL 8.0.22**, `PREPARE` works inside stored procedures but only with **user variables / IN/OUT parameters** as `USAGE` values. Statements that refer to stored-procedure local variables (`DECLARE`-d vars) directly are **not allowed** in the prepared SQL string.

### Example 5.2.3 — dynamic-table-style use (different `WHERE` clauses)

This is the classic use for prepared statements: build the SQL in a string, then prepare + execute it.

```sql
DELIMITER $$

CREATE PROCEDURE search_products(
    IN  p_name       VARCHAR(100),
    IN  p_min_price  DECIMAL(10,2),
    IN  p_max_price  DECIMAL(10,2),
    IN  p_order_by   VARCHAR(50)
)
BEGIN
    SET @sql = 'SELECT id, name, price, stock
                FROM products
                WHERE 1=1';

    IF p_name IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND name LIKE ?');
        SET @arg = CONCAT('%', p_name, '%');
    END IF;

    IF p_min_price IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND price >= ?');
        SET @min := p_min_price;
    END IF;

    IF p_max_price IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND price <= ?');
        SET @max := p_max_price;
    END IF;

    -- Order column name can't use ?, so we either whitelist it or fall back.
    IF p_order_by IN ('price', 'name', 'stock') THEN
        SET @sql = CONCAT(@sql, ' ORDER BY ', p_order_by);
    ELSE
        SET @sql = CONCAT(@sql, ' ORDER BY id');
    END IF;

    PREPARE stmt FROM @sql;

    -- The number of USING arguments must match the number of ? we added.
    IF p_name IS NOT NULL AND p_min_price IS NOT NULL AND p_max_price IS NOT NULL THEN
        EXECUTE stmt USING @arg, @min, @max;
    ELSEIF p_name IS NOT NULL AND p_min_price IS NOT NULL THEN
        EXECUTE stmt USING @arg, @min;
    ELSEIF p_name IS NOT NULL AND p_max_price IS NOT NULL THEN
        EXECUTE stmt USING @arg, @max;
    ELSEIF p_name IS NOT NULL THEN
        EXECUTE stmt USING @arg;
    ELSEIF p_min_price IS NOT NULL AND p_max_price IS NOT NULL THEN
        EXECUTE stmt USING @min, @max;
    ELSEIF p_min_price IS NOT NULL THEN
        EXECUTE stmt USING @min;
    ELSEIF p_max_price IS NOT NULL THEN
        EXECUTE stmt USING @max;
    ELSE
        EXECUTE stmt;
    END IF;

    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;

CALL search_products(NULL,     10,    NULL,  'price');
CALL search_products('Bag',    NULL,  50,    'name');
CALL search_products(NULL,     NULL,  NULL,  NULL);
```

> Notice the **whitelist** check (`IF p_order_by IN ('price', 'name', 'stock')`). Never concatenate user input into SQL fragments that aren't parameterized — `IF column=...` clauses can't be parameterized, so they must be **whitelisted**.

---

## Quick reference — cursor vs prepared statement

| Need                                  | Use                              |
|---------------------------------------|----------------------------------|
| Walk rows from a known SELECT         | **Cursor**                       |
| Run the same query with different values | **Prepared statement**        |
| Build a SQL string at run-time from user inputs | **Prepared statement** with whitelisted identifiers |
| Process millions of rows fast         | Avoid cursors; use set-based `UPDATE` / `INSERT … SELECT` |

---

## ✅ Section 5 — Quick Recap

| Sub-section        | One-line takeaway                                                          |
|--------------------|----------------------------------------------------------------------------|
| 5.1 Cursors        | `DECLARE` a `CURSOR` + `NOT FOUND` handler, then `OPEN` / `FETCH` / `CLOSE`.|
| 5.2 Prepared Stmts | `PREPARE … FROM <sql>; EXECUTE … USING <vars>; DEALLOCATE PREPARE …;`. Use `?` placeholders to defend against SQL injection. |

---

# 🛠️ Practice Section 5 — Try These Yourself

> Reminder of the tables you'll work with:
> ```sql
> USE sp_demo;
> SELECT * FROM products;
> -- id  name       price  stock
> -- 1   Notebook    4.50  100
> -- 2   Pen         1.20  500
> -- 3   Backpack   29.99   25
> -- 4   Headphones 49.00   10
> ```

---

### Question 1 — Cursor: total stock value

**Task.** Procedure `total_stock_value(OUT p_total DECIMAL(12,2))` that uses a **cursor** to walk all rows and compute the sum of `price * stock` into `p_total`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE total_stock_value(OUT p_total DECIMAL(12,2))
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_p    DECIMAL(10,2);
    DECLARE v_s    INT;

    DECLARE cur CURSOR FOR SELECT price, stock FROM products;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET p_total = 0;

    OPEN cur;
    walk: LOOP
        FETCH cur INTO v_p, v_s;
        IF v_done THEN LEAVE walk; END IF;
        SET p_total = p_total + v_p * v_s;
    END LOOP walk;
    CLOSE cur;
END$$

DELIMITER ;

CALL total_stock_value(@t); SELECT @t;
-- (4.5*100)+(1.2*500)+(29.99*25)+(49*10) = 450 + 600 + 749.75 + 490 = 2289.75
```

</details>

---

### Question 2 — Cursor + temporary table: price history

**Task.** Procedure `load_price_history()` that creates a temporary table `price_history(id, name, price, when_run)` and uses a cursor to fill it with the current `products` rows plus `NOW()`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE load_price_history()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id   INT;
    DECLARE v_name VARCHAR(100);
    DECLARE v_p    DECIMAL(10,2);

    DROP TEMPORARY TABLE IF EXISTS price_history;
    CREATE TEMPORARY TABLE price_history (
        id        INT,
        name      VARCHAR(100),
        price     DECIMAL(10,2),
        when_run  DATETIME
    );

    DECLARE cur CURSOR FOR SELECT id, name, price FROM products ORDER BY id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur;
    fill: LOOP
        FETCH cur INTO v_id, v_name, v_p;
        IF v_done THEN LEAVE fill; END IF;
        INSERT INTO price_history VALUES (v_id, v_name, v_p, NOW());
    END LOOP fill;
    CLOSE cur;

    SELECT * FROM price_history;
END$$

DELIMITER ;

CALL load_price_history();
```

</details>

---

### Question 3 — Prepared statement with one parameter

**Task.** Procedure `get_product(IN p_id INT)` that prepares `SELECT id, name, price FROM products WHERE id = ?`, executes it with `p_id`, and deallocates. Test with `p_id = 3`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE get_product(IN p_id INT)
BEGIN
    PREPARE stmt FROM 'SELECT id, name, price FROM products WHERE id = ?';
    EXECUTE stmt USING p_id;
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;

CALL get_product(3);
```

</details>

---

### Question 4 — Prepared statement with optional filter

**Task.** Procedure `find_in_stock(IN p_min_stock INT)` — if `p_min_stock` is `NULL`, return *all* rows; otherwise return rows with `stock >= p_min_stock`. Use a prepared statement so the same logic works in both cases.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE find_in_stock(IN p_min_stock INT)
BEGIN
    IF p_min_stock IS NULL THEN
        PREPARE stmt FROM 'SELECT id, name, stock FROM products ORDER BY id';
        EXECUTE stmt;
    ELSE
        PREPARE stmt FROM 'SELECT id, name, stock FROM products WHERE stock >= ? ORDER BY id';
        EXECUTE stmt USING p_min_stock;
    END IF;

    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;

CALL find_in_stock(NULL);   -- all 4 rows
CALL find_in_stock(50);     -- Notebook (100) and Pen (500) only
```

</details>

---

### Question 5 — Cursor + prepared statement combined

**Task.** Procedure `label_and_search(IN p_min_price DECIMAL(10,2))`:
1. Use a **cursor** to compute (per product) `'cheap'`, `'mid'`, or `'expensive'` (same thresholds as earlier sections) and `INSERT` the labels into a **temporary table** `labels(id, name, label)`.
2. After the cursor, prepare and execute `SELECT id, name, label FROM labels WHERE label = 'expensive'` and print the expensive ones.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE label_and_search(IN p_min_price DECIMAL(10,2))
BEGIN
    DECLARE v_done  INT DEFAULT FALSE;
    DECLARE v_id    INT;
    DECLARE v_name  VARCHAR(100);
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_label VARCHAR(20);

    DROP TEMPORARY TABLE IF EXISTS labels;
    CREATE TEMPORARY TABLE labels (id INT, name VARCHAR(100), label VARCHAR(20));

    DECLARE cur CURSOR FOR SELECT id, name, price FROM products ORDER BY id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur;
    walk: LOOP
        FETCH cur INTO v_id, v_name, v_price;
        IF v_done THEN LEAVE walk; END IF;

        IF v_price < 10 THEN           SET v_label = 'cheap';
        ELSEIF v_price < 40 THEN       SET v_label = 'mid';
        ELSE                           SET v_label = 'expensive';
        END IF;

        INSERT INTO labels VALUES (v_id, v_name, v_label);
    END LOOP walk;
    CLOSE cur;

    PREPARE stmt FROM
        'SELECT id, name, label
           FROM labels
          WHERE label = ?
          ORDER BY id';
    EXECUTE stmt USING p_min_price;
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;

CALL label_and_search('expensive');   -- Headphones
CALL label_and_search('cheap');       -- Notebook, Pen
```

> In the call we pass the literal **string** `'expensive'`; MySQL accepts a string constant as `USING` argument.

</details>


# Section 6. Stored Functions

A **stored function** is like a stored procedure, but **with a strong identity** — it always:

* takes **only `IN`** parameters (no `OUT`, no `INOUT`);
* **returns exactly one value** of a single data type;
* can be used inside any **SQL expression** — `SELECT`, `WHERE`, `ORDER BY`, even in another procedure.

That last point is the key difference from a procedure: **you call a function, you don't `CALL` it**.

```sql
SELECT tax_inclusive(100.00) AS with_tax;   -- direct in SQL
SELECT id, name FROM products
WHERE price > cheap_threshold();            -- inside WHERE
```

---

## 6.1 Creating a stored function

**Syntax:**

```sql
DELIMITER $$

CREATE FUNCTION function_name(
    [IN] p_param type [,...]
)
RETURNS return_type
    [DETERMINISTIC | NOT DETERMINISTIC]
    [SQL DATA | CONTAINS SQL | READS SQL DATA | MODIFIES SQL DATA]
    BEGIN
        -- declarations (DECLARE)
        -- statements
        RETURN expression;     -- must appear, value is sent back to caller
    END$$

DELIMITER ;
```

* `IN` is implicit; you don't need to type it.
* The body **must** contain a `RETURN` statement that produces a value of the declared return type.
* At least one characteristic is required (`DETERMINISTIC`, `READS SQL DATA`, etc.). Functions that read tables must be declared `READS SQL DATA` (or stronger) or the server will refuse them under `binlog_format=ROW`/replication.

### Example 6.1.1 — hello-world function

```sql
DELIMITER $$

CREATE FUNCTION say_hello()
RETURNS VARCHAR(50)
    DETERMINISTIC
BEGIN
    RETURN 'Hello from MySQL function!';
END$$

DELIMITER ;

SELECT say_hello() AS greeting;
```

### Example 6.1.2 — function that takes a parameter

```sql
DELIMITER $$

CREATE FUNCTION price_with_tax(p_price DECIMAL(10,2), p_rate DECIMAL(4,2))
RETURNS DECIMAL(10,2)
    DETERMINISTIC
BEGIN
    RETURN ROUND(p_price * (1 + p_rate), 2);
END$$

DELIMITER ;

SELECT price_with_tax(100.00, 0.07) AS with_tax;
```

> 💡 `DETERMINISTIC` means "given the same inputs, I always return the same value" — it lets MySQL cache results and is **strongly recommended** for any pure math/string function.

### Example 6.1.3 — function that reads from a table

```sql
DELIMITER $$

CREATE FUNCTION get_product_name(p_id INT)
RETURNS VARCHAR(100)
    READS SQL DATA
BEGIN
    DECLARE v_name VARCHAR(100);

    SELECT name INTO v_name FROM products WHERE id = p_id;

    RETURN IFNULL(v_name, 'NOT FOUND');
END$$

DELIMITER ;

SELECT id, get_product_name(id) AS name FROM products;
```

> Important: use `READS SQL DATA` (or `MODIFIES SQL DATA` for write functions). `CONTAINS SQL` is allowed but reads no data — `READS SQL DATA` is the safe default for any table-touching function.

### Example 6.1.4 — function with conditional logic

```sql
DELIMITER $$

CREATE FUNCTION stock_label(p_stock INT)
RETURNS VARCHAR(20)
    DETERMINISTIC
BEGIN
    IF p_stock IS NULL THEN
        RETURN 'Unknown';
    ELSEIF p_stock = 0 THEN
        RETURN 'Out of stock';
    ELSEIF p_stock < 25 THEN
        RETURN 'Low';
    ELSEIF p_stock < 100 THEN
        RETURN 'Medium';
    ELSE
        RETURN 'High';
    END IF;
END$$

DELIMITER ;

SELECT id, name, stock, stock_label(stock) AS label FROM products;
```

### Example 6.1.5 — function that writes to a table

```sql
DROP TABLE IF EXISTS call_log;
CREATE TABLE call_log (
    id        INT PRIMARY KEY AUTO_INCREMENT,
    fn_called VARCHAR(100),
    at_when   DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE FUNCTION log_call(p_name VARCHAR(100))
RETURNS INT
    MODIFIES SQL DATA
BEGIN
    INSERT INTO call_log (fn_called) VALUES (p_name);
    RETURN LAST_INSERT_ID();
END$$

DELIMITER ;

SELECT log_call('first');
SELECT log_call('second');
SELECT * FROM call_log;
```

> ⚠️ Functions that **modify data** can be tricky:
> * They're not allowed to use **prepared statements**.
> * During `INSERT … SELECT` or other top-level statements, MySQL can disable modifying functions to keep replication safe (you may need `--log-bin-trust-function-creators=1` or to add `MODIFIES SQL DATA` — and, on MySQL 8.0+, the binary log format must tolerate it).

### Example 6.1.6 — call a function from a procedure

```sql
DELIMITER $$

CREATE PROCEDURE enrich()
BEGIN
    SELECT id,
           name,
           price,
           get_product_name(id)                                AS same_name,
           price_with_tax(price, 0.07)                         AS with_tax,
           stock_label(stock)                                  AS stock_status,
           log_call(CONCAT('enrich:', name))                  AS log_id
    FROM products;
END$$

DELIMITER ;

CALL enrich();
```

---

## 6.2 Removing a stored function

Just like procedures: `DROP FUNCTION`.

```sql
DROP FUNCTION IF EXISTS say_hello;
DROP FUNCTION IF EXISTS price_with_tax;
DROP FUNCTION IF EXISTS get_product_name;
```

* `IF EXISTS` is optional — recommended so you don't get an error.
* Removing a function does **not** drop any table it touched.
* If another view/procedure references the function, removing it leaves them **invalid** until you update them too.

---

## 6.3 Listing stored functions

### From the command line / MySQL Workbench

```sql
-- All functions in the current database
SHOW FUNCTION STATUS WHERE Db = DATABASE();

-- The source of one function
SHOW CREATE FUNCTION get_product_name;
```

### Filter with `information_schema`

```sql
SELECT ROUTINE_NAME, RETURNS, DATA_TYPE, IS_DETERMINISTIC, CREATED
FROM   information_schema.ROUTINES
WHERE  ROUTINE_SCHEMA = DATABASE()
  AND  ROUTINE_TYPE   = 'FUNCTION';
```

* `DATA_TYPE` is the function's **return type**;
* `IS_DETERMINISTIC` is `'YES'` for `DETERMINISTIC` functions, `'NO'` otherwise;
* Use `ROUTINE_TYPE = 'FUNCTION'` to separate them from procedures (set to `'PROCEDURE'` in 1.8).

### In MySQL Workbench (GUI)

1. **Navigator → Schemas → [your database] → Functions**.
2. Right-click for *Alter Function*, *Drop Function*, etc.

---

## Procedure vs Function — at a glance

| Feature                       | `PROCEDURE`                                  | `FUNCTION`                                 |
|-------------------------------|----------------------------------------------|--------------------------------------------|
| How you invoke it             | `CALL my_proc(args)`                         | In any SQL: `SELECT my_fn(args)`           |
| Parameters                    | `IN`, `OUT`, `INOUT`                         | `IN` only (defaults)                       |
| Returns                       | Zero, one, or many result sets; `OUT` params | Exactly **one** value via `RETURN`         |
| Used inside `SELECT`/`WHERE`  | ❌ No                                        | ✅ Yes                                     |
| Can `RETURN` a value          | ❌ No                                        | ✅ Mandatory                               |
| Transaction / `OUT` allowed   | ✅                                           | ❌ `OUT` / transaction use is limited      |
| Use when…                     | "do a multi-step task"                       | "compute one value I'll reuse in SQL"     |

---

## Common pitfalls

1. **Forgetting the characteristics clause.** Without at least one of `DETERMINISTIC`, `READS SQL DATA`, etc., MySQL throws `ERROR 1418 (HY000)`. Default to `DETERMINISTIC` for pure functions, `READS SQL DATA` for ones that query tables.
2. **`RETURN` missing.** Every function must have a `RETURN` reachable on all paths. Wrap risky code with `BEGIN ... END` and make sure each branch returns.
3. **Calling with the wrong number/type of args.** Like any function call — strict argument checking.
4. **Using `OUT`/`INOUT` parameters.** They're not allowed on functions.
5. **`SIGNAL` inside functions:** allowed, but the SQLSTATE must be valid and the message must be set.

---

## ✅ Section 6 — Quick Recap

| Sub-section             | One-line takeaway                                                           |
|-------------------------|-----------------------------------------------------------------------------|
| 6.1 Creating            | `CREATE FUNCTION name(params) RETURNS type ... BEGIN RETURN value; END`     |
| 6.2 Removing            | `DROP FUNCTION IF EXISTS name;`                                             |
| 6.3 Listing             | `SHOW FUNCTION STATUS`, `SHOW CREATE FUNCTION name`, or `information_schema.ROUTINES` (`ROUTINE_TYPE='FUNCTION'`). |
|                       | **Functions = pure expressions; procedures = multi-step tasks.**             |

---

# 🛠️ Practice Section 6 — Try These Yourself

> Tables in play (the same `sp_demo.products` from previous sections, plus an `orders` you can recreate):
>
> ```sql
> USE sp_demo;
> SELECT * FROM products;
> ```

---

### Question 1 — DETERMINISTIC math function

**Task.** Create function `apply_discount_fn(p_price DECIMAL(10,2), p_pct DECIMAL(4,2))` that returns `p_price * (1 - p_pct / 100)`, rounded to 2 decimals. Mark it `DETERMINISTIC`.

Test: `SELECT apply_discount_fn(100, 20);` should return `80.00`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE FUNCTION apply_discount_fn(
    p_price DECIMAL(10,2),
    p_pct   DECIMAL(4,2)
)
RETURNS DECIMAL(10,2)
    DETERMINISTIC
BEGIN
    RETURN ROUND(p_price * (1 - p_pct / 100), 2);
END$$

DELIMITER ;

SELECT apply_discount_fn(100, 20);   -- 80.00
SELECT apply_discount_fn(49.99, 10); -- 44.99
```

</details>

---

### Question 2 — Function that reads a table

**Task.** Create function `product_price(p_id INT) RETURNS DECIMAL(10,2)` that returns the price of a product (or `NULL` if not found). Use `READS SQL DATA`. Use it in a `SELECT` to list all products with their discounted prices (15% off).

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE FUNCTION product_price(p_id INT)
RETURNS DECIMAL(10,2)
    READS SQL DATA
BEGIN
    DECLARE v_p DECIMAL(10,2);
    SELECT price INTO v_p FROM products WHERE id = p_id;
    RETURN v_p;
END$$

DELIMITER ;

SELECT id,
       get_product_name(id)                  AS name,
       product_price(id)                     AS list_price,
       apply_discount_fn(product_price(id), 15) AS sale_price
FROM products;
```

</details>

---

### Question 3 — Function with control flow

**Task.** Create function `price_tier(p_id INT) RETURNS VARCHAR(10)` that returns `'cheap'`, `'mid'`, or `'expensive'` based on price thresholds (`<10`, `<40`, otherwise). Use the **searched `CASE`** form so it mirrors Section 2.2.2.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE FUNCTION price_tier(p_id INT)
RETURNS VARCHAR(10)
    READS SQL DATA
BEGIN
    DECLARE v_p DECIMAL(10,2);

    SELECT price INTO v_p FROM products WHERE id = p_id;

    CASE
        WHEN v_p IS NULL THEN RETURN 'unknown';
        WHEN v_p < 10    THEN RETURN 'cheap';
        WHEN v_p < 40    THEN RETURN 'mid';
        ELSE                  RETURN 'expensive';
    END CASE;
END$$

DELIMITER ;

SELECT id, name, price, price_tier(id) AS tier FROM products;
```

</details>

---

### Question 4 — Remove + verify

**Task.** Drop function `say_hello` *if it exists*, then list remaining functions. Use both `SHOW FUNCTION STATUS` and a query against `information_schema.ROUTINES`.

<details>
<summary>Show solution</summary>

```sql
DROP FUNCTION IF EXISTS say_hello;

SHOW FUNCTION STATUS WHERE Db = DATABASE();

SELECT ROUTINE_NAME, DATA_TYPE, IS_DETERMINISTIC
FROM   information_schema.ROUTINES
WHERE  ROUTINE_SCHEMA = DATABASE()
  AND  ROUTINE_TYPE   = 'FUNCTION'
ORDER  BY ROUTINE_NAME;
```

</details>

---

### Question 5 — Function used inside a procedure

**Task.** Create function `format_price(p_price DECIMAL(10,2)) RETURNS VARCHAR(20)` that returns the price formatted as `'$X.YZ'` (use `CONCAT('$', FORMAT(p_price, 2))`). Then create procedure `show_prices()` that does `SELECT id, name, format_price(price) AS pretty_price FROM products;` and call it.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE FUNCTION format_price(p_price DECIMAL(10,2))
RETURNS VARCHAR(20)
    DETERMINISTIC
BEGIN
    RETURN CONCAT('$', FORMAT(p_price, 2));
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE show_prices()
BEGIN
    SELECT id,
           name,
           format_price(price)       AS pretty_price,
           format_price(apply_discount_fn(price, 10)) AS pretty_sale
    FROM products;
END$$

DELIMITER ;

CALL show_prices();
```

</details>


# Section 7. Stored Program Security

Procedures and functions don't run "as nobody" — they run **as someone**. Whom MySQL decides to be the "someone" depends on the **SQL SECURITY** mode and the **DEFINER** account recorded with the object. This section covers how to control that, who can run what, and how to lock it down.

---

## 7.1 The two execution contexts

| Context          | Who is checked when the program reads/writes tables? | Recorded in `mysql.proc` as |
|------------------|------------------------------------------------------|------------------------------|
| **`DEFINER`**    | The MySQL user who **created** the program           | `definer` column            |
| **`INVOKER`**    | The MySQL user who **calls** the program             | (derived from the connection) |

By default, **procedures use `DEFINER`**. Beginning with MySQL 8.0.18, the default for stored functions is also **`DEFINER`** (it was `INVOKER` in 5.7). You almost always want to be explicit.

### Why this matters

When a procedure does `SELECT * FROM customers`, MySQL must decide **whose privileges** to use to check that action. With `SQL SECURITY DEFINER`, MySQL uses the creator's privileges — meaning a low-privilege user can still call a procedure that touches tables they couldn't query directly. With `SQL SECURITY INVOKER`, the caller must already have the privileges.

---

## 7.2 Creating with a specific DEFINER and SQL SECURITY

**Syntax:**

```sql
CREATE
    [DEFINER = { user | CURRENT_USER | CURRENT_ROLE }]
    PROCEDURE | FUNCTION
    sp_name(...)
    ...
    [SQL SECURITY { DEFINER | INVOKER } ]
    ...
```

* `DEFINER` defaults to the user who ran `CREATE`. Specify `DEFINER = 'app'@'localhost'` (must be a real account).
* `SQL SECURITY` defaults to `DEFINER` for procedures, and (since 8.0.18) `DEFINER` for functions.

### Example 7.2.1 — explicit DEFINER + SQL SECURITY

```sql
-- Logged in as root
DELIMITER $$

CREATE DEFINER = 'admin'@'localhost'
    PROCEDURE audit_log(IN p_msg VARCHAR(200))
    SQL SECURITY DEFINER
BEGIN
    INSERT INTO audit_log(when_at, msg, by_user)
    VALUES (NOW(), p_msg, CURRENT_USER());
END$$

DELIMITER ;
```

When a user `alice@'%'` calls `CALL audit_log(...)`, the `INSERT` runs with `admin@localhost`'s privileges.

### Example 7.2.2 — INVOKER security

```sql
DELIMITER $$

CREATE DEFINER = 'admin'@'localhost'
    FUNCTION get_my_orders(p_customer_id INT)
    RETURNS INT
    SQL SECURITY INVOKER
    READS SQL DATA
BEGIN
    DECLARE v_n INT;
    SELECT COUNT(*) INTO v_n FROM orders WHERE customer_id = p_customer_id;
    RETURN v_n;
END$$

DELIMITER ;
```

If the caller has no `SELECT` on `orders`, MySQL throws `ERROR 1370 (42000): execute command denied to user 'alice'@'%' for routine 'get_my_orders'`.

### Example 7.2.3 — `ALTER` for an existing program

You can switch `SQL SECURITY` or `DEFINER` for an existing object without dropping it:

```sql
ALTER PROCEDURE audit_log
    SQL SECURITY DEFINER
    COMMENT 'Writes audit rows as the definer';

ALTER FUNCTION get_my_orders
    SQL SECURITY INVOKER;
```

`ALTER` works for: **comment**, **SQL SECURITY**, **DEFINER**, **characteristics** (`DETERMINISTIC` etc.). For the *body* you still drop + recreate.

---

## 7.3 Who can execute?

By default, the **creator** is the only user who can `CALL` a procedure or `SELECT` a function. Use `GRANT EXECUTE` to share it.

```sql
-- Procedure
GRANT EXECUTE ON PROCEDURE sp_demo.audit_log TO 'app_user'@'%';

-- Function
GRANT EXECUTE ON FUNCTION  sp_demo.get_my_orders TO 'app_user'@'%';

-- All routines in a database
GRANT EXECUTE ON sp_demo.* TO 'app_user'@'%';
```

`EXECUTE` is **enough** when the program uses `SQL SECURITY DEFINER` — the caller doesn't need privileges on the underlying tables.

To revoke:

```sql
REVOKE EXECUTE ON PROCEDURE sp_demo.audit_log FROM 'app_user'@'%';
REVOKE EXECUTE ON sp_demo.*              FROM 'app_user'@'%';
```

> 💡 `EXECUTE` is granted at **routine level**, not table level. A user with `EXECUTE` on a routine can call it without any privilege on the routine's underlying tables — that's why `DEFINER` mode is so useful.

---

## 7.4 Grant examples by user

Set up three users so the impact of the modes is concrete:

```sql
-- Create one admin who owns everything, plus two low-privilege callers.
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin_pw';
CREATE USER 'app_user'@'%'      IDENTIFIED BY 'user_pw';
CREATE USER 'guest'@'%'         IDENTIFIED BY 'guest_pw';

GRANT ALL ON sp_demo.* TO 'admin'@'localhost';

-- app_user: can run procedures, but not directly read products
GRANT EXECUTE ON sp_demo.* TO 'app_user'@'%';

-- guest: no privileges yet
```

### Program with `DEFINER` (default)

```sql
DELIMITER $$

CREATE DEFINER = 'admin'@'localhost'
    PROCEDURE price_report()
    SQL SECURITY DEFINER
BEGIN
    SELECT id, name, price FROM products ORDER BY price;
END$$

DELIMITER ;
```

* Logged in as `app_user`: `CALL price_report()` ✅ works (DEFINER has `SELECT`).
* Logged in as `guest`: same call ❌ fails (`guest` has no `EXECUTE`).

### Program with `INVOKER`

```sql
DELIMITER $$

CREATE DEFINER = 'admin'@'localhost'
    PROCEDURE price_report_invoker()
    SQL SECURITY INVOKER
BEGIN
    SELECT id, name, price FROM products ORDER BY price;
END$$

DELIMITER ;
```

* Logged in as `app_user` (no direct `SELECT`): ❌ fails — caller must have the privilege too.
* Logged in as `admin`: ✅ works.

### Pattern: grant `EXECUTE` + the underlying privileges when INVOKER

```sql
GRANT EXECUTE            ON sp_demo.price_report_invoker TO 'app_user'@'%';
GRANT SELECT ON sp_demo.products                         TO 'app_user'@'%';
```

---

## 7.5 Inspecting security metadata

```sql
-- The DEFINER and SQL SECURITY for a routine
SHOW CREATE PROCEDURE audit_log\G
SHOW CREATE FUNCTION  get_my_orders\G

-- Search by DEFINER
SELECT ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE, DEFINER, SECURITY_TYPE
FROM   information_schema.ROUTINES
WHERE  ROUTINE_SCHEMA = 'sp_demo';

-- Who has EXECUTE on a routine?
SELECT GRANTEE, PRIVILEGE_TYPE, IS_GRANTABLE
FROM   information_schema.SCHEMA_PRIVILEGES
WHERE  TABLE_SCHEMA  = 'sp_demo'
  AND  PRIVILEGE_TYPE = 'EXECUTE';
```

* `SECURITY_TYPE` in `information_schema.ROUTINES` is `'DEFINER'` or `'INVOKER'`.
* `DEFINER` is shown in `'user'@'host'` form.

---

## 7.6 Best practices (security checklist)

| ✓  | Practice |
|----|----------|
| ✅ | Be explicit: `SQL SECURITY DEFINER` or `INVOKER` — never leave it to defaults. |
| ✅ | Use a dedicated, low-privilege MySQL account as the `DEFINER` (e.g. `'app_runtime'@'localhost'`) — not `root`. |
| ✅ | Grant `EXECUTE` only to the application role(s) that need the routine. |
| ✅ | Prefer `INVOKER` for functions used in `SELECT … WHERE` so users only see rows they're allowed to see. |
| ✅ | Prefer `DEFINER` for "service" routines (audits, maintenance, clean-up) and grant `EXECUTE` liberally. |
| ⚠️ | Beware of the *function-trap*: a stored function referenced by `SELECT … WHERE` runs **per row** and inherits its caller's context. With `DEFINER`, a low-privilege user can call powerful functions repeatedly — keep them `INVOKER` when in doubt. |
| ⚠️ | When you `ALTER ... DEFINER = other_user@host`, the caller (you) must be a *superuser* or have `SET_USER_ID`/`SUPER`-level privilege; the new definer must already exist. |

---

## 7.7 Putting it all together — a worked example

```sql
-- 0. Make sure the schema + users exist
CREATE DATABASE IF NOT EXISTS sp_demo;
USE sp_demo;

DROP TABLE IF EXISTS audit_log;
CREATE TABLE audit_log (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    when_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    msg    VARCHAR(200),
    by_user VARCHAR(100)
);

-- (Already created above, but re-stated for completeness)
CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'admin_pw';
GRANT ALL ON sp_demo.* TO 'admin'@'localhost';

CREATE USER IF NOT EXISTS 'app_user'@'%'      IDENTIFIED BY 'user_pw';

-- 1. As admin: create the routine
DELIMITER $$

CREATE DEFINER = 'admin'@'localhost'
    PROCEDURE log_event(IN p_msg VARCHAR(200))
    SQL SECURITY DEFINER
BEGIN
    INSERT INTO audit_log (msg, by_user)
    VALUES (p_msg, CURRENT_USER());
END$$

DELIMITER ;

-- 2. As admin: let app_user call it
GRANT EXECUTE ON PROCEDURE sp_demo.log_event TO 'app_user'@'%';

-- 3. Switch to app_user and call it
--    (in MySQL Workbench: "MySQL Connections -> New -> app_user")
CALL sp_demo.log_event('first  call from app_user');
CALL sp_demo.log_event('second call from app_user');

-- 4. As admin again: check the audit table
SELECT * FROM sp_demo.audit_log;
-- Note: `by_user` is 'admin@localhost' even though the *invoking* session was app_user,
--       because SQL SECURITY = DEFINER. That's the whole point.
```

> Try the same exercise but switch to **`SQL SECURITY INVOKER`** and re-run — `app_user` will get `ERROR 1370` (no privilege on `audit_log`) and you'll see the difference clearly.

---

## 7.8 Quick summary — DEFINER vs INVOKER

| Question                                       | `DEFINER`                                  | `INVOKER`                              |
|------------------------------------------------|--------------------------------------------|----------------------------------------|
| Whose privileges matter when reading tables?   | The creator of the routine                 | The caller                             |
| Does the caller need direct table privileges? | **No** — just `EXECUTE`                    | **Yes** — must already have them       |
| Best for…                                      | Service routines, audit, cleanup, ETL jobs | Row-level filtering, per-user reports  |
| Can it leak across users?                      | Yes — runs as someone else                 | No — runs as the caller                |
| Default (MySQL 8.0.18+)?                      | ✅ for both procedures and functions       | (set explicitly if you want it)         |

---

## ✅ Section 7 — Quick Recap

| Sub-section              | One-line takeaway                                                                |
|--------------------------|----------------------------------------------------------------------------------|
| 7.1 Execution contexts   | `DEFINER` = creator's privileges; `INVOKER` = caller's privileges.               |
| 7.2 Create with DEFINER  | `CREATE DEFINER = 'who'@'host' … SQL SECURITY DEFINER \| INVOKER …`              |
| 7.3 Grant EXECUTE        | `GRANT EXECUTE ON PROCEDURE/FUNCTION sp_demo.x TO 'user'@'host';`                |
| 7.4 Practical example    | Grant `EXECUTE` only; pick `DEFINER` for service routines, `INVOKER` for queries.|
| 7.5 Inspect              | `SHOW CREATE …`, `information_schema.ROUTINES` (`SECURITY_TYPE`, `DEFINER`).     |
| 7.6 Best practices       | Use a dedicated definer account, never `root`; be explicit about `SQL SECURITY`. |

---

# 🛠️ Practice Section 7 — Try These Yourself

> The setup below assumes you're connected as a user with privileges to create users and grant. If you're on a shared MySQL, ask your DBA first.

---

### Question 1 — Show your routines' security metadata

**Task.** Run a single `SELECT` against `information_schema.ROUTINES` that shows, for every routine in the current database: `ROUTINE_NAME`, `ROUTINE_TYPE`, `DEFINER`, and `SECURITY_TYPE`. Order by routine type, then name.

<details>
<summary>Show solution</summary>

```sql
SELECT ROUTINE_NAME, ROUTINE_TYPE, DEFINER, SECURITY_TYPE
FROM   information_schema.ROUTINES
WHERE  ROUTINE_SCHEMA = DATABASE()
ORDER  BY ROUTINE_TYPE, ROUTINE_NAME;
```

</details>

---

### Question 2 — Switch SQL SECURITY for an existing routine

**Task.** Take any procedure you already have (e.g. `price_report`) and `ALTER` it to `SQL SECURITY INVOKER`. Then re-show the metadata (Question 1) and verify the change. Switch it back with a second `ALTER` if you want.

<details>
<summary>Show solution</summary>

```sql
ALTER PROCEDURE price_report SQL SECURITY INVOKER;

-- verify
SHOW CREATE PROCEDURE price_report\G

-- revert
ALTER PROCEDURE price_report SQL SECURITY DEFINER;
```

</details>

---

### Question 3 — Create a DEFINER-mode procedure that touches a private table

**Task.**
1. Create table `secret_notes(id INT PK, body VARCHAR(200))` and insert one row.
2. Create procedure `show_first_secret()` with `SQL SECURITY DEFINER` that does `SELECT body FROM secret_notes ORDER BY id LIMIT 1;`.
3. Confirm that, as the *creator*, the procedure returns the row.

<details>
<summary>Show solution</summary>

```sql
DROP TABLE IF EXISTS secret_notes;
CREATE TABLE secret_notes (id INT PRIMARY KEY, body VARCHAR(200));
INSERT INTO secret_notes VALUES (1, 'shhh');

DELIMITER $$

CREATE DEFINER = CURRENT_USER()
    PROCEDURE show_first_secret()
    SQL SECURITY DEFINER
BEGIN
    SELECT body FROM secret_notes ORDER BY id LIMIT 1;
END$$

DELIMITER ;

CALL show_first_secret();
-- 'shhh'
```

</details>

---

### Question 4 — Grant EXECUTE to a low-privilege user

**Task.** Create user `'reader'@'localhost'` with no direct `SELECT` on `products`. Grant them `EXECUTE` on `show_first_secret` from Question 3. Log in as `reader` and call it; it should still return the row. Then `REVOKE` and verify the call fails.

<details>
<summary>Show solution</summary>

```sql
-- as admin
CREATE USER IF NOT EXISTS 'reader'@'localhost' IDENTIFIED BY 'pw';
GRANT EXECUTE ON PROCEDURE sp_demo.show_first_secret TO 'reader'@'localhost';

-- as 'reader'
CALL sp_demo.show_first_secret();   -- works

-- back to admin
REVOKE EXECUTE ON PROCEDURE sp_demo.show_first_secret FROM 'reader'@'localhost';

-- as 'reader'
CALL sp_demo.show_first_secret();   -- ERROR 1370
```

</details>

---

### Question 5 — Audit-table example end-to-end

**Task.** Recreate the `audit_log` example from Section 7.7 on your own server:
1. Create the `audit_log` table.
2. Create a procedure `log_event(IN p_msg VARCHAR(200))` that inserts `(p_msg, CURRENT_USER())` into `audit_log` with `SQL SECURITY DEFINER`.
3. Grant `EXECUTE` to `'reader'@'localhost'`.
4. Call it from `reader`. Verify the row in `audit_log` shows `CURRENT_USER()` as the **definer**, not the invoker.

<details>
<summary>Show solution</summary>

```sql
DROP TABLE IF EXISTS audit_log;
CREATE TABLE audit_log (
    id      INT PRIMARY KEY AUTO_INCREMENT,
    when_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    msg     VARCHAR(200),
    by_user VARCHAR(100)
);

DELIMITER $$

CREATE DEFINER = CURRENT_USER()
    PROCEDURE log_event(IN p_msg VARCHAR(200))
    SQL SECURITY DEFINER
BEGIN
    INSERT INTO audit_log (msg, by_user) VALUES (p_msg, CURRENT_USER());
END$$

DELIMITER ;

GRANT EXECUTE ON PROCEDURE sp_demo.log_event TO 'reader'@'localhost';

-- log in as reader and run:
CALL sp_demo.log_event('reader attempted an action');

-- log back in as admin and check:
SELECT * FROM audit_log;
-- by_user is the DEFINER's account, not 'reader@localhost'
```

</details>


# Section 8. Transactions in Stored Procedures

Stored procedures are one of the most natural places to wrap a transaction. You get **branches**, **loops**, **DECLARE … HANDLER** to react to errors, and a single block where everything happens — perfect for "all or nothing" logic.

This section shows you how to use `START TRANSACTION`, `COMMIT`, `ROLLBACK`, `SAVEPOINT`, isolation levels, and how to combine them with the error-handling from Section 4.

---

## 8.1 What is a "transaction" in MySQL?

A transaction is a group of SQL statements that:

* **Either all succeed** (`COMMIT`), or
* **All get undone** as a group (`ROLLBACK`).

The classic example is moving money between two accounts: you should never see the debit succeed but the credit fail. A transaction guarantees atomicity.

### The four guarantees — ACID

| Letter | Meaning                  | What it gives you                                            |
|--------|--------------------------|--------------------------------------------------------------|
| **A**  | Atomicity                | All-or-nothing: an aborted `ROLLBACK` undoes every change.   |
| **C**  | Consistency              | Constraints (PK/FK/CHECK) hold both before & after.          |
| **I**  | Isolation                | Other sessions see either *all* or *none* of your changes until `COMMIT`. |
| **D**  | Durability               | On `COMMIT`, changes survive crashes.                        |

---

## 8.2 Engine matters: InnoDB vs MyISAM

> ⚠️ **Transactions only work in InnoDB.**
> If your table is `MyISAM` (or `MEMORY`, etc.), `START TRANSACTION` is silently accepted but `ROLLBACK` will be a no-op.

```sql
-- Confirm engine
SELECT ENGINE FROM information_schema.TABLES
WHERE  TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'products';
-- must say 'InnoDB'
```

Convert if needed:

```sql
ALTER TABLE products ENGINE = InnoDB;
```

> The `sp_demo` schema from Section 1 uses InnoDB by default on every modern MySQL — so all the examples below just work.

---

## 8.3 Autocommit — the default mode

MySQL's `autocommit` is **on** by default: every `INSERT/UPDATE/DELETE/REPLACE` becomes its own mini-transaction and is committed immediately.

You can check / change it for the current session:

```sql
SELECT @@autocommit;            -- 1 = on (default), 0 = off

SET autocommit = 0;             -- session level
SET SESSION autocommit = 0;     -- same thing, explicit
SET GLOBAL  autocommit = 0;     -- affects all NEW connections (SUPER privilege)
```

When `autocommit = 0`, a `BEGIN` / `START TRANSACTION` block runs until you `COMMIT` or `ROLLBACK`, after which MySQL **re-starts** the transaction (called a **multi-statement transaction**).

> 💡 Inside a stored procedure, transactions are scoped to the procedure unless you `COMMIT`/`ROLLBACK`. The connection's autocommit setting still applies when the procedure returns.

---

## 8.4 The four transaction-control statements

| Statement                          | What it does                                                          |
|------------------------------------|-----------------------------------------------------------------------|
| `START TRANSACTION` *(or `BEGIN`)* | Begin a new transaction. Implicitly ends any open one.                |
| `COMMIT`                           | Make all changes in this transaction **permanent**.                   |
| `ROLLBACK`                         | Undo every change in this transaction (back to `START TRANSACTION`).  |
| `ROLLBACK TO SAVEPOINT name`        | Undo changes **after** `SAVEPOINT name`, but keep ones before.        |
| `SAVEPOINT name`                   | Place a marker you can roll back to.                                  |
| `RELEASE SAVEPOINT name`           | Delete a savepoint (does not roll back).                              |
| `SET TRANSACTION ISOLATION LEVEL …` | Set isolation for the next transaction.                               |

`BEGIN` is the lightweight alias for `START TRANSACTION`, but `START TRANSACTION` accepts options like `WITH CONSISTENT SNAPSHOT` (used by backups).

---

## 8.5 Your first transactional procedure

A simple "transfer stock between two products" routine. Either both updates land, or none do.

### Setup

```sql
DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
    id    INT PRIMARY KEY,
    name  VARCHAR(50),
    bal   DECIMAL(12,2) NOT NULL DEFAULT 0
);
INSERT INTO accounts VALUES (1, 'Alice', 100.00), (2, 'Bob', 100.00);
```

### Example 8.5.1 — transfer funds, all-or-nothing

```sql
DELIMITER $$

CREATE PROCEDURE transfer_funds(
    IN p_from INT,
    IN p_to   INT,
    IN p_amt  DECIMAL(12,2)
)
BEGIN
    -- 1. Input validation
    IF p_amt <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Amount must be positive';
    END IF;

    -- 2. Begin transaction
    START TRANSACTION;

    UPDATE accounts SET bal = bal - p_amt WHERE id = p_from;
    UPDATE accounts SET bal = bal + p_amt WHERE id = p_to;

    -- 3. Either keep both changes…
    COMMIT;
END$$

DELIMITER ;

-- Try it
CALL transfer_funds(1, 2, 25.00);
SELECT * FROM accounts;
-- Alice: 75.00, Bob: 125.00
```

But notice: the `SIGNAL` raises an error *before* the transaction begins, so the caller learns about the bad input. The `COMMIT` already happened, so what if one of the `UPDATE`s throws an error (e.g. id not found)? Let's fix that next.

---

## 8.6 Combining transactions with error handlers

This is where procedures shine. Pair `START TRANSACTION` with a `DECLARE … HANDLER` so any error inside automatically triggers `ROLLBACK`.

### Example 8.6.1 — auto-rollback on error

```sql
DELIMITER $$

CREATE PROCEDURE transfer_funds_safe(
    IN p_from INT,
    IN p_to   INT,
    IN p_amt  DECIMAL(12,2)
)
BEGIN
    DECLARE v_bal DECIMAL(12,2);

    -- Generic error handler -> roll back, then re-raise
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE accounts SET bal = bal - p_amt WHERE id = p_from;

    -- Defensive check: did the row actually update?
    SELECT bal INTO v_bal FROM accounts WHERE id = p_from;
    IF v_bal < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;

    UPDATE accounts SET bal = bal + p_amt WHERE id = p_to;

    COMMIT;
END$$

DELIMITER ;
```

What happens:

| Scenario                              | Handler fires? | Outcome               |
|---------------------------------------|----------------|-----------------------|
| `p_amt = 25`, both accounts exist      | No             | `COMMIT` — balances updated. |
| Sender has only $10, you try to send $50 | No  *(signal fires inside the same tx)* | `ROLLBACK` — both rows untouched. |
| `p_to` doesn't exist                   | No — `UPDATE` matched 0 rows, the `SELECT` returns NULL. The `IF` succeeds but balances might be inconsistent.  | Need stronger checks (see below). |

### Example 8.6.2 — defensive: ensure both updates touched a row

```sql
DELIMITER $$

CREATE PROCEDURE transfer_funds_v2(
    IN p_from INT,
    IN p_to   INT,
    IN p_amt  DECIMAL(12,2)
)
BEGIN
    DECLARE v_rows INT;
    DECLARE v_bal DECIMAL(12,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Sender
    UPDATE accounts SET bal = bal - p_amt WHERE id = p_from;
    SELECT ROW_COUNT() INTO v_rows;
    IF v_rows = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sender account not found';
    END IF;

    SELECT bal INTO v_bal FROM accounts WHERE id = p_from;
    IF v_bal < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;

    -- Receiver
    UPDATE accounts SET bal = bal + p_amt WHERE id = p_to;
    SELECT ROW_COUNT() INTO v_rows;
    IF v_rows = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Receiver account not found';
    END IF;

    COMMIT;
END$$

DELIMITER ;
```

Now a bad `p_to` triggers the `SIGNAL`, which bubbles up to the handler, which rolls back — *no partial debit gets committed.*

---

## 8.7 Savepoints — partial rollback inside one transaction

Sometimes you don't want to give up everything; you just want to undo "the last step." `SAVEPOINT … ROLLBACK TO` lets you keep some changes and discard others.

### Example 8.7.1 — three steps, savepoint around step 2

```sql
DELIMITER $$

CREATE PROCEDURE three_steps()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT after_step1;   -- undo step 2/3, keep step 1
        -- (no RESIGNAL: the procedure succeeded from its own point of view)
    END;

    START TRANSACTION;

    -- Step 1: guaranteed to land
    INSERT INTO accounts(id, name, bal) VALUES (3, 'Carol', 0);

    SAVEPOINT after_step1;

    -- Step 2: might fail (e.g. violates a unique key)
    UPDATE accounts SET bal = bal + 100 WHERE id = 3;

    -- Step 3
    UPDATE accounts SET bal = bal + 1   WHERE id = 1;

    COMMIT;
END$$

DELIMITER ;
```

| What happens on step 2                                 | Outcome                                  |
|--------------------------------------------------------|------------------------------------------|
| Step 2 succeeds, step 3 succeeds                        | `COMMIT` — both updates land.            |
| Step 2 throws (e.g. UNIQUE violation, deadlock)         | `ROLLBACK TO SAVEPOINT after_step1` keeps Carol, undoes everything since the savepoint; the procedure exits cleanly. |
| Step 2 succeeds but step 3 fails                        | Handler's `ROLLBACK TO SAVEPOINT` keeps Carol + the step 2 increment, undoes the step 3 +100 on Alice. |

> 💡 Savepoints **don’t free up locks** — the rows you touched before the savepoint are still row-locked by this transaction.

---

## 8.8 Isolation levels — what other sessions see

Isolation level decides what your transaction allows / prevents. Set it for the **next** transaction with `SET TRANSACTION` (note: not `SET SESSION`).

| Level (lowest → highest)                  | Dirty reads | Non-repeatable reads | Phantom reads |
|------------------------------------------|-------------|----------------------|---------------|
| `READ UNCOMMITTED`                       | possible    | possible             | possible      |
| `READ COMMITTED` (default in many RDBMS) | prevented   | possible             | possible      |
| `REPEATABLE READ` *(MySQL default)*       | prevented   | prevented            | possible*     |
| `SERIALIZABLE`                           | prevented   | prevented            | prevented     |

\* In InnoDB, `REPEATABLE READ` also avoids most phantoms thanks to next-key locks.

### Setting it inside a procedure

```sql
-- Affects the NEXT transaction only
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Or only inside this procedure
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

> MySQL's default **`REPEATABLE READ`** is a solid choice. Drop to `READ COMMITTED` for heavy concurrent write workloads where you can tolerate "rows may shift under your SELECT" — typical pattern for batch jobs.

---

## 8.9 Common gotchas

| # | Trap                                                                                                                          | Fix                                                              |
|---|-------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------|
| 1| Mixing transactional and non-transactional tables (e.g. InnoDB + MyISAM in one procedure).                                    | Either switch the table to InnoDB, or document the partial atomicity. |
| 2| Using `START TRANSACTION` inside a `WHILE` loop without `COMMIT` per batch.                                                   | Add `START TRANSACTION; … COMMIT;` around batches (every 1 000–10 000 rows). |
| 3| Issuing `ROLLBACK` inside a trigger. **Triggers can't roll back transactions started outside the trigger.**                    | Make your trigger fail; the outer transaction's handler will roll back. |
| 4| Cursors inside transactions can hold locks for a long time.                                                                  | Keep the cursor batch small; commit between batches.             |
| 5| A function cannot contain a `COMMIT` or `ROLLBACK`. Functions are implicitly single-statement.                                  | Use a **procedure** for transactional logic.                     |
| 6| `START TRANSACTION` inside a function is silently ignored.                                                                    | Same: use a procedure.                                           |
| 7| `SIGNAL` inside a `DECLARE … HANDLER` block — must be the **last** statement in the block if your handler is `EXIT`.         | Put `RESIGNAL` first; then your `SIGNAL`.                        |
| 8| DDL (`CREATE`, `ALTER`, `DROP`) inside a transaction — MySQL **implicitly commits** the current transaction before running it.| Avoid transactional DDL; or be aware it ends the transaction.    |

---

## 8.10 Deadlocks — when two transactions wait on each other

InnoDB automatically detects deadlocks and rolls back the **smaller** transaction, returning `ER_LOCK_DEADLOCK` (error 1213). Your handler must be ready:

```sql
DECLARE EXIT HANDLER FOR 1213          -- or: FOR SQLEXCEPTION
BEGIN
    ROLLBACK;
    -- Optionally: retry
    RESIGNAL;
END;
```

A common retry loop **outside** MySQL looks like:

```sql
CALL transfer_funds_v2(1, 2, 25);    -- may fail with deadlock
-- Application-level: try up to 3 times with a tiny sleep between attempts.
```

Inside the procedure you can also retry by looping on a savepoint:

```sql
DECLARE v_deadlock INT DEFAULT 1;
WHILE v_deadlock <= 3 DO
    BEGIN
        DECLARE EXIT HANDLER FOR 1213
        BEGIN
            SET v_deadlock = v_deadlock + 1;
            ROLLBACK;
        END;

        START TRANSACTION;
        /* ... your work ... */
        COMMIT;
        SET v_deadlock = 999;   -- success
    END;
END WHILE;
```

---

## ✅ Section 8 — Quick Recap

| Sub-section                | One-line takeaway                                                       |
|----------------------------|-------------------------------------------------------------------------|
| 8.1 ACID                   | Atomic / Consistent / Isolated / Durable.                                |
| 8.2 Engines                | Transactions need **InnoDB**.                                            |
| 8.3 Autocommit             | On by default; set `0` per-session for multi-statement transactions.    |
| 8.4 Control statements     | `START TRANSACTION … COMMIT` / `ROLLBACK` / `SAVEPOINT`.                |
| 8.5 First procedure        | `START TRANSACTION` → updates → `COMMIT`.                               |
| 8.6 + Handler              | `EXIT HANDLER FOR SQLEXCEPTION … ROLLBACK; RESIGNAL;`                   |
| 8.7 Savepoints             | `SAVEPOINT name`; `ROLLBACK TO SAVEPOINT name` for partial undo.        |
| 8.8 Isolation              | `REPEATABLE READ` (default) → `READ COMMITTED` → `SERIALIZABLE`.        |
| 8.9 / 8.10 Gotchas & retries | Functions can't transact; DDL implicit-commits; handle `ER_LOCK_DEADLOCK`. |

---

# 🛠️ Practice Section 8 — Try These Yourself

> Re-use the `accounts` table from Section 8.5 if you have it. Otherwise re-create it:
>
> ```sql
> DROP TABLE IF EXISTS accounts;
> CREATE TABLE accounts (id INT PRIMARY KEY, name VARCHAR(50), bal DECIMAL(12,2) NOT NULL DEFAULT 0);
> INSERT INTO accounts VALUES (1, 'Alice', 100.00), (2, 'Bob', 100.00), (3, 'Carol', 0);
> ```

---

### Question 1 — All-or-nothing transfer

**Task.** Write a procedure `transfer(p_from, p_to, p_amt)` that:
1. Verifies `p_amt > 0`.
2. Runs both `UPDATE`s inside a single transaction.
3. `COMMIT`s on success.
4. Rolls back if any statement throws an `SQLEXCEPTION`.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE transfer(IN p_from INT, IN p_to INT, IN p_amt DECIMAL(12,2))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_amt <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Amount must be positive';
    END IF;

    START TRANSACTION;
        UPDATE accounts SET bal = bal - p_amt WHERE id = p_from;
        UPDATE accounts SET bal = bal + p_amt WHERE id = p_to;
    COMMIT;
END$$

DELIMITER ;

CALL transfer(1, 2, 30.00);
SELECT * FROM accounts;
-- Alice: 70, Bob: 130
```

</details>

---

### Question 2 — Insufficient-funds check inside a transaction

**Task.** Extend Question 1 to additionally `SIGNAL SQLSTATE '45000'` with message `'Insufficient funds'` if the sender's balance would go below zero. The whole transaction must roll back when this signal fires.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE transfer_with_balance_check(
    IN p_from INT, IN p_to INT, IN p_amt DECIMAL(12,2)
)
BEGIN
    DECLARE v_bal DECIMAL(12,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        UPDATE accounts SET bal = bal - p_amt WHERE id = p_from;
        SELECT bal INTO v_bal FROM accounts WHERE id = p_from;
        IF v_bal < 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds';
        END IF;
        UPDATE accounts SET bal = bal + p_amt WHERE id = p_to;
    COMMIT;
END$$

DELIMITER ;

-- Failure case
CALL transfer_with_balance_check(1, 2, 9999.00);   -- ERROR: Insufficient funds
SELECT * FROM accounts;   -- unchanged
```

</details>

---

### Question 3 — Savepoint after the first INSERT

**Task.** Create `seed_carol()` that:
1. `START TRANSACTION`.
2. `INSERT`s Carol with `bal = 0`.
3. Creates a `SAVEPOINT after_carol`.
4. Does an `UPDATE accounts SET bal = bal + 50 WHERE id = 3`.
5. Has a handler that rolls back **to the savepoint** (not the whole transaction).
6. `COMMIT`s at the end.

Test it by deliberately causing the `UPDATE` to fail (e.g. wrong column type or by `SIGNAL`-ing). Then check that **Carol was inserted** but the `+50` did **not** land.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE seed_carol(IN p_should_fail BOOLEAN)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT after_carol;
    END;

    START TRANSACTION;
        INSERT INTO accounts(id, name, bal) VALUES (99, 'Dave', 0);
        SAVEPOINT after_carol;
        IF p_should_fail THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Forced failure after savepoint';
        END IF;
        UPDATE accounts SET bal = bal + 50 WHERE id = 99;
    COMMIT;
END$$

DELIMITER ;

CALL seed_carol(TRUE);
SELECT * FROM accounts WHERE id = 99;
-- name: Dave, bal: 0   <- INSERT kept, +50 undone
```

</details>

---

### Question 4 — Roll back every other INSERT

**Task.** Write a procedure `insert_pairs()` that, in one transaction, inserts two new accounts (`Eve` and `Frank`) **with a savepoint between them**. Add an `SQLEXCEPTION` handler that rolls back to the savepoint only when Frank's insert fails. Roll back the whole transaction if Eve's fails.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE insert_pairs()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;           -- default: undo everything
        RESIGNAL;
    END;

    START TRANSACTION;
        INSERT INTO accounts(id, name, bal) VALUES (50, 'Eve',   0);
        SAVEPOINT after_eve;
        INSERT INTO accounts(id, name, bal) VALUES (50, 'Frank', 0); -- PK collision
    COMMIT;
END$$

DELIMITER ;

CALL insert_pairs();   -- ERROR 1062 (duplicate key); entire transaction rolled back
SELECT * FROM accounts WHERE id = 50;
-- (no rows)
```

To **only** undo Frank, wrap Frank's insert in a nested `BEGIN … END` with its own handler that does `ROLLBACK TO SAVEPOINT after_eve` and lets the outer transaction continue:

```sql
DELIMITER $$

CREATE PROCEDURE insert_pairs_recover()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        INSERT INTO accounts(id, name, bal) VALUES (50, 'Eve', 0);
        SAVEPOINT after_eve;

        BEGIN
            DECLARE EXIT HANDLER FOR 1062
            BEGIN
                ROLLBACK TO SAVEPOINT after_eve;
            END;
            INSERT INTO accounts(id, name, bal) VALUES (50, 'Frank', 0);
        END;
    COMMIT;
END$$

DELIMITER ;

CALL insert_pairs_recover();
SELECT * FROM accounts WHERE id = 50;
-- 50, Eve, 0   <- Eve inserted, Frank undone
```

</details>

---

### Question 5 — Set isolation level for one transaction

**Task.** Create `tx_serializable_demo()` that **only for the next transaction** sets `ISOLATION LEVEL SERIALIZABLE`, then does `START TRANSACTION; SELECT COUNT(*) INTO … FROM accounts; COMMIT;`. After the call, verify that the *session's* isolation level did not change permanently.

<details>
<summary>Show solution</summary>

```sql
DELIMITER $$

CREATE PROCEDURE tx_serializable_demo(OUT p_n INT)
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    START TRANSACTION;
        SELECT COUNT(*) INTO p_n FROM accounts;
    COMMIT;
END$$

DELIMITER ;

CALL tx_serializable_demo(@n);
SELECT @n;

-- Outside the procedure, isolation level is back to the default
SELECT @@transaction_isolation;
-- READ REPEATABLE (MySQL's REPEATABLE READ)
```

> Use `SET TRANSACTION ISOLATION LEVEL …` (singular) to scope the change to the *next* transaction. `SET SESSION TRANSACTION ISOLATION LEVEL …` would persist for the whole session.

</details>

