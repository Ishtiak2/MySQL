-- Section 2. Managing MySQL Triggers
-- Example 2.1.1 — strip whitespace from title/author BEFORE INSERT
-- Source: MySQL-Triggers.md

DROP TRIGGER IF EXISTS books_before_insert_trim;

CREATE TRIGGER books_before_insert_trim
    BEFORE INSERT
    ON books
    FOR EACH ROW
BEGIN
    SET NEW.title  = TRIM(NEW.title);
    SET NEW.author = TRIM(NEW.author);
END;

-- Try it
INSERT INTO books (title, author, price, in_stock)
VALUES ('  Refactoring  ', '  Martin Fowler ', 35.00, 3);

SELECT id, title, author FROM books;
