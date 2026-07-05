-- Section 10. Show triggers — listing and patterns
-- Example 10.1.2 — use SHOW CREATE TRIGGER to grab the exact definition
-- Source: MySQL-Triggers.md

USE trigger_demo;

-- Print the full CREATE statement for one trigger.
-- In the mysql CLI, append \G for a vertical, easy-to-read layout:
--   SHOW CREATE TRIGGER books_after_update_log_price\G
SHOW CREATE TRIGGER books_after_update_log_price;