-- Section 9. Multiple triggers for the same event and time
-- Setup under § 9.3 — extra table for the second AFTER INSERT trigger
-- Source: MySQL-Triggers.md

DROP TABLE IF EXISTS book_notifications;
CREATE TABLE book_notifications (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    book_id      INT NOT NULL,
    title        VARCHAR(150),
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    sent         TINYINT DEFAULT 0   -- 0 = pending email, 1 = sent
);
