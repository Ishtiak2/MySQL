-- Section 7. BEFORE DELETE trigger
-- Example 7.1.2 — copy about-to-be-deleted rows to books_archive (preview)
-- Source: MySQL-Triggers.md
-- Note: Section 8 covers the canonical AFTER DELETE archive pattern.

DROP TRIGGER IF EXISTS books_before_delete_copy_to_archive;

CREATE TRIGGER books_before_delete_copy_to_archive
    BEFORE DELETE
    ON books
    FOR EACH ROW
BEGIN
    INSERT INTO books_archive (id, title, author, price)
    VALUES (OLD.id, OLD.title, OLD.author, OLD.price);
END;

TRUNCATE TABLE books_archive;

-- We need to be able to delete a row that has stock for this example,
-- so temporarily drop the Section 7 block:
DROP TRIGGER IF EXISTS books_before_delete_block_in_stock;

DELETE FROM books WHERE title = 'Clean Code';

-- books row is gone...
SELECT title FROM books WHERE title = 'Clean Code';

-- ...but it lived on in books_archive
SELECT * FROM books_archive;