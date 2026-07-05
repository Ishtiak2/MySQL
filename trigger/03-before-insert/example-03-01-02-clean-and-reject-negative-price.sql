-- Section 3. BEFORE INSERT trigger
-- Example 3.1.2 — trim title and reject negative prices with SIGNAL
-- Source: MySQL-Triggers.md

DROP TRIGGER IF EXISTS books_before_insert_clean;

CREATE TRIGGER books_before_insert_clean
    BEFORE INSERT
    ON books
    FOR EACH ROW
BEGIN
    -- 1. Trim the title
    SET NEW.title = TRIM(NEW.title);

    -- 2. Reject negative prices
    IF NEW.price < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Price cannot be negative';
    END IF;
END;

-- Valid row: succeeds (title is trimmed)
INSERT INTO books (title, author, price, in_stock)
VALUES ('  Clean Architecture  ', 'Robert C. Martin', 32.00, 5);

-- Invalid row: rejected — outer INSERT is rolled back
INSERT INTO books (title, author, price, in_stock)
VALUES ('Bad Book', 'No One', -9.99, 1);
-- ERROR 1644 (45000): Price cannot be negative

-- Verify the bad row was NOT saved
SELECT id, title, author, price FROM books ORDER BY id;
