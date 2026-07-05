-- Section 10. Show triggers — listing and patterns
-- Example 10.1.1 — list triggers with SHOW TRIGGERS and information_schema
-- Source: MySQL-Triggers.md

USE trigger_demo;

-- 1. List every trigger in the current database
SHOW TRIGGERS;

-- 2. Filter by name pattern
SHOW TRIGGERS LIKE 'books%';
SHOW TRIGGERS LIKE '%after_update%';
SHOW TRIGGERS LIKE 'orders\_%';   -- escape the underscore

-- 3. Programmatic access via information_schema
SELECT
    trigger_name        AS name,
    event_object_table  AS tbl,
    action_timing       AS timing,
    event_manipulation  AS event,
    created
FROM information_schema.triggers
WHERE trigger_schema = DATABASE()
ORDER BY tbl, timing, event, name;

-- 4. Just the triggers on the books table
SELECT *
FROM information_schema.triggers
WHERE event_object_table = 'books'
  AND trigger_schema     = DATABASE();