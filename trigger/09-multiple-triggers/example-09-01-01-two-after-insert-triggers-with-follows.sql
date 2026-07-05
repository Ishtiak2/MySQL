-- Section 9. Multiple triggers for the same event and time
-- Example 9.1.1 — two AFTER INSERT triggers on books, ordered with FOLLOWS
-- Source: MySQL-Triggers.md

-- 1. Trigger A — create a placeholder review row (re-create from Section 4)
DROP TRIGGER IF EXISTS books_after_insert_create_review;

CREATE TRIGGER books_after_insert_create_review
    AFTER INSERT
    ON books
    FOR EACH ROW
BEGIN
    INSERT INTO book_reviews (book_id, reviewer, rating, comment)
    VALUES (NEW.id, 'pending', NULL, NULL);
END;

-- 2. Trigger B — queue a notification, ordered AFTER trigger A
DROP TRIGGER IF EXISTS books_after_insert_notify;

CREATE TRIGGER books_after_insert_notify
    AFTER INSERT
    ON books
    FOR EACH ROW
    FOLLOWS books_after_insert_create_review
BEGIN
    INSERT INTO book_notifications (book_id, title)
    VALUES (NEW.id, NEW.title);
END;

-- Clean the side tables so the demo is clear
TRUNCATE TABLE book_reviews;
TRUNCATE TABLE book_notifications;

-- One INSERT — both triggers fire, in FOLLOWS order
INSERT INTO books (title, author, price, in_stock)
VALUES ('Designing Data-Intensive Applications', 'Martin Kleppmann', 45.00, 6);

-- Both side effects visible
SELECT * FROM book_reviews;
SELECT * FROM book_notifications;