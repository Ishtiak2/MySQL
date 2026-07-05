# MySQL Events — A Beginner's Guide

A hands-on, section-by-section walkthrough of MySQL **events** with simple explanations and runnable examples.

> **How to read this guide:** each sub-section has a short plain-English explanation followed by a small example you can paste into MySQL Workbench, the `mysql` client, or any GUI. The examples all share one small sample schema so you can build it once and reuse it.

---

## Table of Contents

- **Section 1. Introduction to MySQL Events**
  - 1.1 What is an event?
  - 1.2 When is an event useful?
  - 1.3 Event scheduler — the on/off switch
  - 1.4 One-time vs recurring events
  - 1.5 Anatomy of an event
  - 1.6 Why use events? (advantages & disadvantages)
- **Section 2. Create an event**
  - 2.1 Creating an event — the basic recipe
  - 2.2 One-time event (run once, on a schedule)
  - 2.3 Recurring event with `EVERY n SECOND/MINUTE/HOUR/DAY`
  - 2.4 Recurring event at a specific clock time
  - 2.5 Recurring event with `STARTS … ENDS …`
  - 2.6 The `ON COMPLETION` clause — keep / discard after a one-time event finishes
- **Section 3. Alter an event**
  - 3.1 Disabling an event
  - 3.2 Enabling an event
  - 3.3 Changing the schedule / body
  - 3.4 Renaming an event
- **Section 4. Drop an event**
  - 4.1 Dropping an event with `DROP EVENT`
  - 4.2 `IF EXISTS` to avoid errors
- **Section 5. Show events — listing and patterns**
  - 5.1 `SHOW EVENTS` in the current database
  - 5.2 `SHOW EVENTS FROM db_name`
  - 5.3 `SHOW EVENTS LIKE 'pattern'`
  - 5.4 `SHOW EVENTS WHERE …` — filtering by status
  - 5.5 `information_schema.events` — the full view
  - 5.6 `SHOW CREATE EVENT` — see the exact definition

---

## The sample schema we will use

We will use one small **orders** schema for almost every example. Run this once before any other snippet in this guide:

```sql
CREATE DATABASE IF NOT EXISTS event_demo;
USE event_demo;

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    customer    VARCHAR(100) NOT NULL,
    amount      DECIMAL(10,2) NOT NULL,
    status      VARCHAR(20)  NOT NULL DEFAULT 'NEW',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO orders (customer, amount, status, created_at) VALUES
('Alice',  49.99, 'NEW',       NOW()),
('Bob',    19.50, 'NEW',       NOW()),
('Carol', 120.00, 'PAID',      NOW()),
('Dave',    8.75, 'NEW',       NOW()),
('Eve',   250.00, 'CANCELLED', NOW());

DROP TABLE IF EXISTS event_log;
CREATE TABLE event_log (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    message     VARCHAR(255),
    logged_at   DATETIME DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS orders_summary;
CREATE TABLE orders_summary (
    total_orders  INT NOT NULL DEFAULT 0,
    total_amount  DECIMAL(12,2) NOT NULL DEFAULT 0,
    refreshed_at  DATETIME DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO orders_summary (total_orders, total_amount)
VALUES (0, 0);
```

You now have three tables to play with:

| Table | What it is for |
|-------|---------------|
| `orders`           | The main table events will read, update, or summarize |
| `event_log`        | A "trace" table — each event writes a row here so we can SEE it fire |
| `orders_summary`   | A 1-row dashboard table kept fresh by a recurring event |

---

> **Before you start — turn the scheduler ON**
>
> By default the MySQL **event scheduler is OFF**. Events you `CREATE` will exist but never run until the scheduler is enabled. Run this **once** per MySQL server (or include it in your `00-setup.sql`):
>
> ```sql
> SET GLOBAL event_scheduler = ON;
> ```
>
> To turn it off again:
>
> ```sql
> SET GLOBAL event_scheduler = OFF;
> ```
>
> You only need the `EVENT` privilege on the schema to create events there.

---

# Section 1. Introduction to MySQL Events

## 1.1 What is an event?

An **event** is a named SQL block that the MySQL server runs for you **on a schedule** — once, or over and over again.

> Think of it like an **alarm clock**: you don't push the button every minute yourself — you set it once, and it rings on its own.

Two important facts:

1. An event is **owned by one specific database** — it lives inside a schema, just like tables and triggers.
2. An event has a **body of SQL** (a single statement, or a `BEGIN … END` block) and a **schedule** ("run every 1 minute", "run tomorrow at 09:00", "run once in 30 seconds", …).

Events are sometimes called **scheduled jobs** — that's the same idea.

## 1.2 When is an event useful?

A handful of recurring chores that you'd otherwise do by hand or with a cron job:

| Real-life example | What the event does |
|---|---|
| "Archive any `orders` row older than 30 days, every night at 02:00." | Runs a `DELETE`/`INSERT…SELECT` every night |
| "Recompute `orders_summary` every 5 minutes." | Runs `REPLACE INTO orders_summary SELECT …` |
| "Send a 'happy new hour' notification at 09:00 on the 1st of every month." | Inserts a row into a notifications log |
| "Drop temporary data 1 hour after it was created." | One-time event with `AT CURRENT_TIMESTAMP + INTERVAL 1 HOUR` |
| "Delete unverified users who never logged in within 24 h of signing up." | Hourly cleanup |

If your app already has a job queue (Sidekiq, Celery, Laravel Scheduler, …) you don't need MySQL events. But for tiny, **inside-the-database** automation, they are perfect.

## 1.3 Event scheduler — the on/off switch

MySQL has a server-level setting called `event_scheduler`. It can be one of three values:

| Value | Meaning |
|---|---|
| `ON`   | The scheduler thread is running; events fire on time |
| `OFF`  | The scheduler thread is **stopped**; events are stored but never run |
| `DISABLED` | The scheduler was never started and can't be turned on at runtime (only configurable in `my.cnf`) |

Check what it is:

```sql
SHOW VARIABLES LIKE 'event_scheduler';
```

Turn it on (and remember: this is a **GLOBAL** setting, not a session one):

```sql
SET GLOBAL event_scheduler = ON;
```

> 💡 On many hosted MySQL services (AWS RDS, Azure Database for MySQL, …) this is already `ON`. On a freshly-installed local `mysqld` it is usually `OFF`.

## 1.4 One-time vs recurring events

| Kind | When it runs | Clause |
|---|---|---|
| **One-time** | Once, at a specific moment in the future | `AT <timestamp>` |
| **Recurring**  | Every `n` units of time, starting/ending optionally | `EVERY n <UNIT> [STARTS …] [ENDS …]` |

The `<UNIT>` for recurring events is one of: `YEAR`, `QUARTER`, `MONTH`, `DAY`, `HOUR`, `MINUTE`, `SECOND`, `WEEK`, `YEAR_MONTH`, `DAY_HOUR`, `DAY_MINUTE`, `DAY_SECOND`, `HOUR_MINUTE`, `HOUR_SECOND`, `MINUTE_SECOND`. The most common ones you will use are `SECOND`, `MINUTE`, `HOUR`, `DAY`, `WEEK`, `MONTH`.

## 1.5 Anatomy of an event

A complete event looks like this:

```sql
CREATE EVENT my_event
    ON SCHEDULE
        EVERY 1 HOUR                       -- OR: AT CURRENT_TIMESTAMP + INTERVAL 1 HOUR
    [STARTS CURRENT_TIMESTAMP]            -- optional
    [ENDS   CURRENT_TIMESTAMP + INTERVAL 1 DAY]  -- optional
    [ON COMPLETION [NOT] PRESERVE]        -- for one-time events
    [ENABLE | DISABLE | DISABLE ON SLAVE]
    [COMMENT 'free-text description']
DO
    -- one statement…
    INSERT INTO event_log (message) VALUES ('my_event fired');
    -- OR a BEGIN … END block for many statements
```

Every event has these parts:

| Part | What it is |
|---|---|
| `name` | The event name, unique in its database |
| `ON SCHEDULE …` | When to fire (once or recurring) |
| `DO` | The body — what SQL to run |
| `ON COMPLETION [NOT] PRESERVE` | What to do **after** a one-time event finishes (`PRESERVE` keeps it, `NOT PRESERVE` drops it) |
| `ENABLE` / `DISABLE` | Whether the event is currently active |

## 1.6 Why use events?

| Advantages ✅ | Disadvantages ❌ |
|---|---|
| No external cron / job-runner needed | Less visible than app-level jobs (no nice dashboard) |
| Lives with the data — easy to ship with a schema migration | Errors are logged but easy to miss |
| Can run inside the same transaction as the data | Cannot return a result set to a client |
| Set-and-forget: schedule is declarative | One mistake can touch **every** row in a table — test first! |

---

# Section 2. Create an event

## 2.1 Creating an event — the basic recipe

Creating an event is a 4-step recipe.

### Step 1 — Pick the **schedule**
"Run **once** in 30 seconds" → `AT CURRENT_TIMESTAMP + INTERVAL 30 SECOND`
"Run **every** 1 minute"  → `EVERY 1 MINUTE`

### Step 2 — Pick the **body**
A single `INSERT`, `UPDATE`, `DELETE`, `CALL`, … or a `BEGIN … END` block.

### Step 3 — Pick the **name**
Use the pattern `{what}_{when_it_fires}`:

```
orders_archive_old_rows      (recurring archive)
orders_one_off_greet         (one-time greet)
```

### Step 4 — Run the `CREATE EVENT` statement
You **don't** change the delimiter for events — the parser already knows `CREATE EVENT … END;`. Just write:

```sql
CREATE EVENT orders_one_off_greet
    ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
    INSERT INTO event_log (message) VALUES ('Hello from a one-time event!');
```

### Anatomy of the CREATE EVENT statement

```
CREATE EVENT  orders_one_off_greet          ← name (unique in its database)
    ON SCHEDULE                              ← "what's the schedule?"
        AT CURRENT_TIMESTAMP + INTERVAL 1 MINUTE   ← run once, 1 minute from now
DO
    INSERT INTO event_log (message) VALUES ('…');  ← the body
```

### Things you are NOT allowed to do inside an event body

| Not allowed | Why |
|---|---|
| `RETURN` a result set the way a `SELECT` does | Event bodies don't return rows to clients |
| Recursive events that re-schedule themselves in tricky ways | Keep it simple |
| Statements that require a connection user (e.g. interactive things) | Events run as the definer, no client session |

## 2.2 One-time event (`AT …`)

A one-time event runs **once** at the given moment, then either disappears (`ON COMPLETION NOT PRESERVE`, the default) or stays around disabled (`ON COMPLETION PRESERVE`).

```sql
DROP EVENT IF EXISTS orders_one_off_greet;
CREATE EVENT orders_one_off_greet
    ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
    ON COMPLETION NOT PRESERVE
    COMMENT 'My very first one-time event'
DO
    INSERT INTO event_log (message)
    VALUES (CONCAT('Hello! Fired at ', NOW()));
```

- `AT CURRENT_TIMESTAMP + INTERVAL 1 MINUTE` means "1 minute after now".
- `ON COMPLETION NOT PRESERVE` is the default — once it fires, the event is dropped automatically.
- If you want to **see** what it logged after it fires:

```sql
SELECT * FROM event_log ORDER BY id DESC;
```

## 2.3 Recurring event (`EVERY …`)

Use `EVERY n <UNIT>` to run something on a loop. The simplest version starts **right now** and runs **forever**:

```sql
DROP EVENT IF EXISTS orders_refresh_summary;
CREATE EVENT orders_refresh_summary
    ON SCHEDULE EVERY 1 MINUTE
    STARTS CURRENT_TIMESTAMP
    COMMENT 'Recompute orders_summary every minute'
DO
    -- Recompute the totals each time we fire
    INSERT INTO orders_summary (total_orders, total_amount)
    SELECT COUNT(*), COALESCE(SUM(amount), 0)
    FROM orders
    ON DUPLICATE KEY UPDATE
        total_orders = VALUES(total_orders),
        total_amount = VALUES(total_amount);

    -- And write a heartbeat row so we can see it ran
    INSERT INTO event_log (message)
    VALUES (CONCAT('orders_refresh_summary ran at ', NOW()));
```

A few notes:

- `EVERY 1 MINUTE` — runs every minute. Use `EVERY 5 SECOND`, `EVERY 10 MINUTE`, `EVERY 1 HOUR`, `EVERY 1 DAY`, etc.
- `STARTS CURRENT_TIMESTAMP` — start **now**. If you omit this, MySQL starts the schedule as if the event had just been created.
- There is no `ENDS`, so it runs forever (until you `DROP EVENT` or `ALTER EVENT … DISABLE`).

## 2.4 Recurring event at a specific clock time

You can combine `EVERY 1 DAY` with `STARTS 'YYYY-MM-DD HH:MM:SS'` to mean "every night at 03:00":

```sql
DROP EVENT IF EXISTS orders_archive_old_rows;
CREATE EVENT orders_archive_old_rows
    ON SCHEDULE EVERY 1 DAY
    STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 3 HOUR)
    COMMENT 'Archive orders older than 7 days, nightly at 03:00'
DO
    -- 'Old' = created more than 7 days ago.
    -- For this tutorial we use 0 seconds so the demo produces output.
    DELETE FROM orders
    WHERE created_at < NOW() - INTERVAL 0 SECOND;

    INSERT INTO event_log (message)
    VALUES (CONCAT('orders_archive_old_rows fired at ', NOW()));
```

> 📝 **Reading the start time:**
> `STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 3 HOUR)` is "tomorrow, plus 3 hours" — i.e. tomorrow at 03:00. The parentheses are important.

## 2.5 Recurring event with `STARTS … ENDS …`

`ENDS` lets an event stop running automatically on its own. Useful for short-lived batch windows:

```sql
DROP EVENT IF EXISTS orders_archive_2h;
CREATE EVENT orders_archive_2h
    ON SCHEDULE EVERY 1 MINUTE
    STARTS CURRENT_TIMESTAMP
    ENDS   CURRENT_TIMESTAMP + INTERVAL 2 HOUR
    COMMENT 'Run every minute for 2 hours, then stop on its own'
DO
    INSERT INTO event_log (message)
    VALUES (CONCAT('orders_archive_2h fired at ', NOW()));
```

After 2 hours MySQL drops the event (`ON COMPLETION NOT PRESERVE` is the default for one-shots; for recurring events with `ENDS`, MySQL keeps the event definition but leaves it disabled).

## 2.6 The `ON COMPLETION` clause — keep / discard after a one-time event finishes

This clause only matters for **one-time** events.

| Value | After the event fires once… |
|---|---|
| `ON COMPLETION NOT PRESERVE` *(default)* | The event is **dropped automatically** |
| `ON COMPLETION PRESERVE`           | The event stays in the database, but is now **disabled** (so it won't re-run) |

```sql
-- Stays around after firing — useful as a paper trail
DROP EVENT IF EXISTS orders_one_off_greet;
CREATE EVENT orders_one_off_greet
    ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 30 SECOND
    ON COMPLETION PRESERVE
    COMMENT 'Keep me after I fire'
DO
    INSERT INTO event_log (message) VALUES ('I fired once and lived to tell about it');
```

> 💡 **Tip:** for recurring events, `ON COMPLETION PRESERVE` after the `ENDS` time means "keep the event around (disabled) once it has run out the clock".

---

# Section 3. Alter an event

You don't drop and re-create an event to tweak it — use `ALTER EVENT`. It can change almost every part of the definition: the body, the schedule, the comment, the enabled state, etc.

## 3.1 Disabling an event

Disabling does **not** delete the event — it just freezes it. The definition stays put, and you can re-enable it later.

```sql
ALTER EVENT orders_refresh_summary DISABLE;
```

To confirm, `SHOW EVENTS` will show `Status: DISABLED` (see Section 5).

## 3.2 Enabling an event

```sql
ALTER EVENT orders_refresh_summary ENABLE;
```

You can also flip the schedule back on at the same time:

```sql
ALTER EVENT orders_refresh_summary
    ENABLE
    ON SCHEDULE EVERY 5 MINUTE;
```

> 📝 In `ALTER EVENT`, you write **only what you want to change**. Anything you leave out stays the same.

## 3.3 Changing the schedule / body

Replace the schedule:

```sql
ALTER EVENT orders_refresh_summary
    ON SCHEDULE EVERY 30 SECOND;
```

Replace the body:

```sql
ALTER EVENT orders_refresh_summary
DO
    INSERT INTO event_log (message) VALUES ('New body — still ticking');
```

Replace both at once:

```sql
ALTER EVENT orders_refresh_summary
    ON SCHEDULE EVERY 2 MINUTE
    COMMENT 'Slower, leaner body'
DO
    INSERT INTO event_log (message)
    VALUES (CONCAT('Refreshed at ', NOW()));
```

Replace the `ON COMPLETION` rule:

```sql
ALTER EVENT orders_archive_2h
    ON COMPLETION PRESERVE;
```

## 3.4 Renaming an event

There is **no `RENAME EVENT`** in MySQL. To rename, drop and re-create:

```sql
DROP EVENT IF EXISTS orders_archive_2h;
CREATE EVENT orders_archive_two_hour_window
    ON SCHEDULE EVERY 1 MINUTE
    ENDS   CURRENT_TIMESTAMP + INTERVAL 2 HOUR
DO
    INSERT INTO event_log (message)
    VALUES (CONCAT('orders_archive_two_hour_window fired at ', NOW()));
```

---

# Section 4. Drop an event

## 4.1 Dropping an event with `DROP EVENT`

Dropping is permanent — the definition is gone.

```sql
DROP EVENT orders_refresh_summary;
```

Things to know:

- You drop an event **by name only**. There is no `DROP EVENT … ON table;` here.
- You need the `EVENT` privilege for that schema.
- Dropping an event does **not** touch any data in your tables — it only removes the schedule.

## 4.2 `IF EXISTS` to avoid errors

Without `IF EXISTS`, dropping a missing event throws:

```
ERROR 1304 (ER_SP_DOES_NOT_EXIST): Event 'foo' does not exist
```

Adding `IF EXISTS` makes the statement a no-op when the event isn't there:

```sql
DROP EVENT IF EXISTS orders_refresh_summary;
```

This is the version you usually want — especially in setup / migration scripts where the event may or may not already exist.

### Verify it is gone

```sql
SHOW EVENTS;                       -- lists all events in the current database
SHOW EVENTS LIKE 'orders%';        -- filter by name pattern
SHOW CREATE EVENT event_name;       -- exact definition (handy to copy before dropping!)
```

> 💡 **Tip:** before dropping, run `SHOW CREATE EVENT your_event;` so you have the exact `CREATE EVENT` statement saved — useful if you need to recreate it later. We will see `SHOW EVENTS` in detail in Section 5.

---

# Section 5. Show events — listing and patterns

There are three ways to look at events:

1. `SHOW EVENTS [FROM db] [LIKE 'pattern']` — short summary
2. `SHOW CREATE EVENT event_name` — the exact `CREATE EVENT` statement for one event
3. Querying `information_schema.events` — the full set of columns

## 5.1 `SHOW EVENTS` in the current database

```sql
USE event_demo;
SHOW EVENTS;
```

You get a row per event with columns like:

| Column | Meaning |
|---|---|
| `Db` | The database the event lives in |
| `Name` | The event name |
| `Definer` | The MySQL user who created it |
| `Time zone` | The time zone the schedule is interpreted in |
| `Type` | `ONE TIME` or `RECURRING` |
| `Execute At` | For one-time events: when it will fire |
| `Interval Value` / `Interval Field` | For recurring events: every `…` `…` |
| `Starts` / `Ends` | First / last execution window |
| `Status` | `ENABLED` or `DISABLED` |
| `Originator` | The server id that created it (for replication) |
| `character_set_client`, `collation_connection` | Session character set at create time |

## 5.2 `SHOW EVENTS FROM db_name`

You don't need to `USE` the database first — you can name it:

```sql
SHOW EVENTS FROM event_demo;
```

## 5.3 `SHOW EVENTS LIKE 'pattern'`

`LIKE` filters by **event name**:

```sql
SHOW EVENTS FROM event_demo LIKE 'orders%';
```

That's how you find, for example, every event whose name starts with `orders_`.

## 5.4 `SHOW EVENTS WHERE …` — filtering by status

`WHERE` filters by **any column**. The two most useful filters:

Find every **enabled** event:

```sql
SHOW EVENTS FROM event_demo WHERE Status = 'ENABLED';
```

Find every **disabled** event:

```sql
SHOW EVENTS FROM event_demo WHERE Status = 'DISABLED';
```

You can also filter on `Type`:

```sql
SHOW EVENTS FROM event_demo WHERE Type = 'RECURRING';
SHOW EVENTS FROM event_demo WHERE Type = 'ONE TIME';
```

> 💡 `Status = 'SLAVESIDE DISABLED'` is also possible — that means the event was created on a master and intentionally disabled on a replica. You'll mostly see this in replication setups.

## 5.5 `information_schema.events` — the full view

When `SHOW EVENTS` doesn't give you enough, drop down to `information_schema.events`. It's a normal table you can `SELECT` from, with the full schedule and the *body of the event* in the `EVENT_DEFINITION` column:

```sql
SELECT
    EVENT_SCHEMA,
    EVENT_NAME,
    EVENT_TYPE,           -- 'ONE TIME' or 'RECURRING'
    STATUS,               -- 'ENABLED' / 'DISABLED'
    INTERVAL_VALUE,
    INTERVAL_FIELD,
    STARTS,
    ENDS,
    EXECUTE_AT,
    EVENT_DEFINITION      -- the SQL inside the DO
FROM information_schema.events
WHERE EVENT_SCHEMA = 'event_demo'
ORDER BY EVENT_NAME;
```

This is the only place where you can see the **body** of the event without first running `SHOW CREATE EVENT` for every row.

## 5.6 `SHOW CREATE EVENT` — see the exact definition

```sql
-- Paste into an interactive mysql client (the \G pager gives vertical output).
-- In batch mode, drop the \G and end with a regular ; instead.
SHOW CREATE EVENT orders_refresh_summary\G
```

You'll get back something like:

```
*************************** 1. row ***************************
               Event: orders_refresh_summary
            sql_mode: ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,...
       time_zone: SYSTEM
       Create Event: CREATE EVENT `orders_refresh_summary` ON SCHEDULE
                       EVERY 1 MINUTE STARTS CURRENT_TIMESTAMP ...
       character_set_client: utf8mb4
       collation_connection: utf8mb4_0900_ai_ci
  Database Collation: utf8mb4_0900_ai_ci
```

That `Create Event:` line is the exact statement you can copy/paste into a migration script. **Always run this before dropping an event you might need again.**

### Quick recap

- `SHOW EVENTS [FROM db] [LIKE 'p']` — list events with a useful summary.
- `SHOW EVENTS … WHERE Status = 'ENABLED'` — filter by status or type.
- `SELECT … FROM information_schema.events` — same data, plus the event body and all timing columns.
- `SHOW CREATE EVENT name` — see and copy the original definition.

---

> **Next:** when you are ready, we'll continue with hands-on exercises in `02-create-event/`, `03-alter-event/`, `04-drop-event/`, and `05-show-events/` — every example comes as a standalone `.sql` file in this tutorial's `event/` folder.
