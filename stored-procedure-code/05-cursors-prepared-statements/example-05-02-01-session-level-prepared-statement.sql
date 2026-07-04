-- Section 5. Cursors and Prepared Statements
-- Example 5.2.1 — session-level prepared statement
-- Source: MySQL-Stored-Procedures.md

PREPARE q FROM 'SELECT id, name, price FROM products WHERE price > ?';

SET @min := 10;
EXECUTE q USING @min;

SET @min := 30;
EXECUTE q USING @min;

DEALLOCATE PREPARE q;
