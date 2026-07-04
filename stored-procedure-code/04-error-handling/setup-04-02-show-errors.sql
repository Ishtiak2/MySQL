-- Section 4. Error Handling
-- Setup under § 4.2 — SHOW ERRORS
-- Source: MySQL-Stored-Procedures.md

SELECT 'x' INTO @x;
SHOW ERRORS;
-- After error 1324 (Undeclared variable: @y)

SELECT n FROM nonexistent_db.numbers;
SHOW ERRORS;
-- After error 1146 (Table doesn't exist)
