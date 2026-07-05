-- Section 8. AFTER DELETE trigger
-- Example 8.1.2 — archive the row AND log the deletion to books_audit
-- Source: MySQL-Triggers.md

DROP TRIGGER IF EXISTS books_after_delete_archive;

CREATE TRIGGER books_after_delete_archive
    AFTER DELETE
    ON books
    FOR EACH ROW
BEGIN
    -- 1. Tombstone the row
    INSERT INTO books_archive (id, title, author, price)
    VALUES (OLD.id, OLD.title, OLD.author, OLD.price);

    -- 2. Log who deleted it (audit row with old_price == new_price)
    INSERT INTO books_audit (book_id, old_price, new_price, changed_by)
    VALUES (OLD.id, OLD.price, OLD.price,
            CONCAT('deleted by ', CURRENT_USER()));
END;

TRUNCATE TABLE books_archive;
DELETE FROM books_audit;

DROP TRIGGER IF EXISTS books_before_delete_block_in_stock;

DELETE FROM books WHERE title = 'The Pragmatic Coder';

-- Both side effects visible
SELECT * FROM books_archive;
SELECT * FROM books_audit;