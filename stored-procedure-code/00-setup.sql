-- 00-setup.sql
-- Canonical schema for the MySQL-Stored-Procedures tutorial.
-- Run once before any per-section scripts:
--   mysql -u root -p < 00-setup.sql

-- 1. Main sample schema
CREATE DATABASE IF NOT EXISTS sp_demo;
USE sp_demo;

DROP TABLE IF EXISTS products;
CREATE TABLE products (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    stock        INT NOT NULL DEFAULT 0
);

INSERT INTO products (name, price, stock) VALUES
('Notebook',    4.50, 100),
('Pen',         1.20, 500),
('Backpack',   29.99,  25),
('Headphones', 49.00,  10);

-- 2. Number helper (1..10) for loop demos
DROP TABLE IF EXISTS numbers;
CREATE TABLE numbers (n INT PRIMARY KEY);

INSERT INTO numbers (n) VALUES
(1),(2),(3),(4),(5),(6),(7),(8),(9),(10);

-- 3. Error-log table used by Section 4 examples
DROP TABLE IF EXISTS error_log;
CREATE TABLE error_log (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    when_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    proc_name   VARCHAR(100),
    err_code    INT,
    err_msg     VARCHAR(500)
);

-- 4. Cursor demo tables (orders + items)
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS order_items;
CREATE TABLE orders      (id INT PRIMARY KEY, customer VARCHAR(50));
CREATE TABLE order_items (order_id INT, product_id INT, qty INT);

INSERT INTO orders VALUES (1, 'Alice'), (2, 'Bob');
INSERT INTO order_items VALUES
    (1, 1, 2), (1, 2, 5), (1, 3, 1),
    (2, 2, 3), (2, 4, 1);

-- 5. Function demo: call_log
DROP TABLE IF EXISTS call_log;
CREATE TABLE call_log (
    id       INT PRIMARY KEY AUTO_INCREMENT,
    when_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    msg      VARCHAR(200)
);

-- 6. Security demo: audit_log
DROP TABLE IF EXISTS audit_log;
CREATE TABLE audit_log (
    id      INT PRIMARY KEY AUTO_INCREMENT,
    when_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    msg     VARCHAR(200),
    by_user VARCHAR(100)
);

-- 7. Security demo: secret_notes (private table for INVOKER demo)
DROP TABLE IF EXISTS secret_notes;
CREATE TABLE secret_notes (id INT PRIMARY KEY, body VARCHAR(200));
INSERT INTO secret_notes VALUES (1, 'shhh');

-- 8. Transactions demo: accounts
DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
    id    INT PRIMARY KEY,
    name  VARCHAR(50),
    bal   DECIMAL(12,2) NOT NULL DEFAULT 0
);
INSERT INTO accounts VALUES (1, 'Alice', 100.00), (2, 'Bob', 100.00), (3, 'Carol', 0);

SELECT 'Schema ready.' AS status;
