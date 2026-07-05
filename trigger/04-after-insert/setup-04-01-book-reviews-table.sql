-- Section 4. AFTER INSERT trigger
-- Setup under § 4.2 — extra table for the AFTER INSERT examples
-- Source: MySQL-Triggers.md

DROP TABLE IF EXISTS book_reviews;
CREATE TABLE book_reviews (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    book_id     INT NOT NULL,
    reviewer    VARCHAR(100) DEFAULT 'pending',
    rating      TINYINT,
    comment     VARCHAR(500),
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);
