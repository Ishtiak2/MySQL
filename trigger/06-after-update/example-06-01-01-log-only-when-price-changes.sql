-- Section 6. AFTER UPDATE trigger
-- Example 6.1.1 — log each real price change into books_audit
-- Source: MySQL-Triggers.md

DROP TRIGGER IF EXISTS books_after_update_log_price;

CREATE TRIGGER books_after_update_log_price
    AFTER UPDATE
    ON books
    FOR EACH ROW
BEGIN
    -- Only log when the price actually changed (skip noisy title-only updates)
    IF OLD.price <> NEW.price THEN
        INSERT INTO books_audit (book_id, old_price, new_price, changed_by)
        VALUES (
            OLD.id,
            OLD.price,
            NEW.price,
            CURRENT_USER()
        );
    END IF;
END;

-- Make sure the audit table starts empty
SELECT * FROM books_audit;

-- 1. Price change — one audit row
UPDATE books SET price = 18.50 WHERE title = 'Dune';
SELECT * FROM books_audit;

-- 2. Another price change — second audit row
UPDATE books SET price = 17.00 WHERE title = 'Dune';
SELECT * FROM books_audit ORDER BY id;

-- 3. Title-only update — no audit row should be written
UPDATE books SET title = 'Dune (2nd ed.)' WHERE title = 'Dune';
SELECT COUNT(*) AS price_changes FROM books_audit;
