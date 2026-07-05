-- Section 5. BEFORE UPDATE trigger
-- Example 5.1.1 — reject negative price or negative stock with SIGNAL
-- Source: MySQL-Triggers.md

DROP TRIGGER IF EXISTS books_before_update_validate;

CREATE TRIGGER books_before_update_validate
    BEFORE UPDATE
    ON books
    FOR EACH ROW
BEGIN
    IF NEW.price < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Price cannot be negative';
    END IF;

    IF NEW.in_stock < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'in_stock cannot be negative';
    END IF;
END;

-- 1. A valid update — should succeed
UPDATE books SET price = 19.99 WHERE title = 'Dune';
SELECT id, title, price FROM books WHERE title = 'Dune';

-- 2. An invalid update — should be rejected
UPDATE books SET price = -1.00 WHERE title = 'Dune';
-- ERROR 1644 (45000): Price cannot be negative

-- 3. Verify the row was NOT changed
SELECT id, title, price FROM books WHERE title = 'Dune';

-- 4. Another invalid update — negative stock
UPDATE books SET in_stock = -5 WHERE title = 'The Hobbit';
-- ERROR 1644 (45000): in_stock cannot be negative