-- Section 5. Cursors and Prepared Statements
-- Setup under § 5.2 — Prepared Statements
-- Source: MySQL-Stored-Procedures.md

PREPARE stmt_name FROM 'SELECT ... WHERE id = ?';

-- pass the value (only constants / user variables / local vars are allowed here)
SET @id := 42;
EXECUTE stmt_name USING @id;

-- free server-side resources
DEALLOCATE PREPARE stmt_name;
