-- Section 4. AFTER INSERT trigger
-- Example 4.1.1 — auto-create a placeholder review row for each new book
-- Source: MySQL-Triggers.md

DROP TRIGGER IF EXISTS books_after_insert_create_review;

CREATE TRIGGER books_after_insert_create_review
    AFTER INSERT
    ON books
    FOR EACH ROW
BEGIN
    INSERT INTO book_reviews (book_id, reviewer, rating, comment)
    VALUES (
        NEW.id,           -- the id of the book that just landed
        'pending',        -- no reviewer yet
        NULL,
        NULL
    );
END;

-- Look at reviews before
SELECT * FROM book_reviews;

-- Add a book — a placeholder review row is created automatically
INSERT INTO books (title, author, price, in_stock)
VALUES ('Clean Architecture', 'Robert C. Martin', 32.00, 5);

SELECT * FROM book_reviews;

-- More inserts to see the trigger fire per row
INSERT INTO books (title, author, price, in_stock) VALUES
('The Phoenix Project',        'Gene Kim',  24.00, 4),
('Site Reliability Engineering','Google',    45.00, 2);

SELECT b.id, b.title, r.reviewer, r.rating
FROM books b
LEFT JOIN book_reviews r ON r.book_id = b.id
ORDER BY b.id;
