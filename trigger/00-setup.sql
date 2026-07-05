-- 00-setup.sql
-- Canonical schema + seed data for the MySQL-Triggers tutorial.
-- Run once before any per-section scripts:
--   mysql -u root -p < 00-setup.sql

-- 1. Main sample schema
CREATE DATABASE IF NOT EXISTS trigger_demo;
USE trigger_demo;

-- Main table: books
DROP TABLE IF EXISTS books;
CREATE TABLE books (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    title       VARCHAR(150) NOT NULL,
    author      VARCHAR(100) NOT NULL,
    price       DECIMAL(10,2) NOT NULL,
    in_stock    INT NOT NULL DEFAULT 0
);

INSERT INTO books (title, author, price, in_stock) VALUES
('The Hobbit',          'J.R.R. Tolkien', 12.50, 10),
('Dune',                'Frank Herbert',   15.00,  5),
('Clean Code',          'Robert C. Martin',30.00,  2),
('The Pragmatic Coder', 'Andy Hunt',       28.00,  7);

-- Summary table kept in sync by triggers in Section 3
DROP TABLE IF EXISTS books_stock_summary;
CREATE TABLE books_stock_summary (
    total_books    INT NOT NULL DEFAULT 0,
    total_in_stock INT NOT NULL DEFAULT 0,
    last_updated   DATETIME DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO books_stock_summary (total_books, total_in_stock)
VALUES (0, 0);

-- Audit log used by Section 6 (AFTER UPDATE) and Section 8 (AFTER DELETE)
DROP TABLE IF EXISTS books_audit;
CREATE TABLE books_audit (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    book_id     INT,
    old_price   DECIMAL(10,2),
    new_price   DECIMAL(10,2),
    changed_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    changed_by  VARCHAR(100)                 -- filled in by the trigger
);

-- Tombstone / archive table used by Section 8 (AFTER DELETE)
DROP TABLE IF EXISTS books_archive;
CREATE TABLE books_archive (
    id          INT,
    title       VARCHAR(150),
    author      VARCHAR(100),
    price       DECIMAL(10,2),
    deleted_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);
