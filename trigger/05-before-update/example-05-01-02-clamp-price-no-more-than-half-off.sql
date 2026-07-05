-- Section 5. BEFORE UPDATE trigger
-- Example 5.1.2 — silently clamp discount price to at least 50% of the original
-- Source: MySQL-Triggers.md

DROP TRIGGER IF EXISTS books_before_update_clamp_price;

CREATE TRIGGER books_before_update_clamp_price
    BEFORE UPDATE
    ON books
    FOR EACH ROW
BEGIN
    IF NEW.price < OLD.price * 0.5 THEN
        SET NEW.price = OLD.price * 0.5;
    END IF;
END;

-- Original price of 'The Hobbit' is 12.50
UPDATE books SET price = 1.00 WHERE title = 'The Hobbit';

-- The trigger clamped it to 6.25 (= 12.50 * 0.5)
SELECT title, price FROM books WHERE title = 'The Hobbit';