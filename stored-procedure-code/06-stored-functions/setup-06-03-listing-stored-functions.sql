-- Section 6. Stored Functions
-- Setup under § 6.3 — Listing stored functions
-- Source: MySQL-Stored-Procedures.md

-- All functions in the current database
SHOW FUNCTION STATUS WHERE Db = DATABASE();

-- The source of one function
SHOW CREATE FUNCTION get_product_name;
