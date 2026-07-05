-- Section 7. BEFORE DELETE trigger
-- Example 7.1.1 — reject deletion of a book that still has stock
-- Source: MySQL-Triggers.md

DROP TRIGGER IF EXISTS books_before_delete_block_in_stock;

CREATE TRIGGER books_before_delete_block_in_stock
    BEFORE DELETE
    ON books
    FOR EACH ROW
BEGIN
    IF OLD.in_stock > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete a book that still has copies in stock';
    END IF;
END;

SELECT id, title, in_stock FROM books;

-- 1. Try to delete a book that still has stock → should fail
DELETE FROM books WHERE title = 'The Hobbit';
-- ERROR 1644 (45000): Cannot delete a book that still has copies in stock

-- 2. Row is still there
SELECT id, title FROM books WHERE title = 'The Hobbit';

-- 3. Set stock to 0 first, then delete → should succeed
UPDATE books SET in_stock = 0 WHERE title = 'The Hobbit';
DELETE FROM books WHERE title = 'The Hobbit';
SELECT id, title FROM books WHERE title = 'The Hobbit';
