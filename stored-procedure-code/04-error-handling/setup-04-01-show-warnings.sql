-- Section 4. Error Handling
-- Setup under § 4.1 — SHOW WARNINGS
-- Source: MySQL-Stored-Procedures.md

-- Force a string → integer truncation warning, then inspect it
SELECT CAST('abc' AS UNSIGNED);   -- 0  (with warning)

SHOW WARNINGS;
