-- Section 8. AFTER DELETE trigger
-- Example 8.1.1 — copy deleted rows into books_archive (canonical AFTER DELETE pattern)
-- Source: MySQL-Triggers.md

DROP TRIGGER IF EXISTS books_after_delete_archive;

CREATE TRIGGER books_after_delete_archive
    AFTER DELETE
    ON books
    FOR EACH ROW
BEGIN
    INSERT INTO books_archive (id, title, author, price)
    VALUES (OLD.id, OLD.title, OLD.author, OLD.price);
END;

-- Clean slate
TRUNCATE TABLE books_archive;

-- We don't want Section 7's "in_stock > 0" rule blocking this demo,
-- so temporarily drop it:
DROP TRIGGER IF EXISTS books_before_delete_block_in_stock;

-- 1. Delete a book
DELETE FROM books WHERE title = 'Clean Code';

-- 2. The row is gone from books...
SELECT title FROM books WHERE title = 'Clean Code';

-- 3. ...but it lives on in books_archive
SELECT * FROM books_archive;