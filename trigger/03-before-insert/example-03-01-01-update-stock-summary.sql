-- Section 3. BEFORE INSERT trigger
-- Example 3.1.1 — keep books_stock_summary in sync on every INSERT
-- Source: MySQL-Triggers.md

DROP TRIGGER IF EXISTS books_before_insert_update_summary;

CREATE TRIGGER books_before_insert_update_summary
    BEFORE INSERT
    ON books
    FOR EACH ROW
BEGIN
    UPDATE books_stock_summary
    SET total_books    = total_books + 1,
        total_in_stock = total_in_stock + NEW.in_stock;
END;

-- Current state of the summary
SELECT * FROM books_stock_summary;

-- Insert a new book — summary should reflect it
INSERT INTO books (title, author, price, in_stock)
VALUES ('Refactoring', 'Martin Fowler', 35.00, 4);

SELECT * FROM books_stock_summary;

-- A few more inserts
INSERT INTO books (title, author, price, in_stock) VALUES
('Domain-Driven Design', 'Eric Evans',        40.00, 3),
('The Mythical Man-Month', 'Fred Brooks',     22.50, 6);

SELECT * FROM books_stock_summary;
