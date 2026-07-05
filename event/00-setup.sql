-- 00-setup.sql
-- Canonical schema + seed data for the MySQL-Events tutorial.
-- Run once before any per-section scripts:
--   mysql -u root -p < 00-setup.sql

-- 1. Main sample schema
CREATE DATABASE IF NOT EXISTS event_demo;
USE event_demo;

-- Main table: orders
-- Each row is one order. New rows are inserted by the app;
-- our events will periodically clean up / summarise this table.
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    customer    VARCHAR(100) NOT NULL,
    amount      DECIMAL(10,2) NOT NULL,
    status      VARCHAR(20)  NOT NULL DEFAULT 'NEW',  -- NEW, PAID, CANCELLED
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO orders (customer, amount, status, created_at) VALUES
('Alice',  49.99, 'NEW',       NOW()),
('Bob',    19.50, 'NEW',       NOW()),
('Carol', 120.00, 'PAID',      NOW()),
('Dave',    8.75, 'NEW',       NOW()),
('Eve',   250.00, 'CANCELLED', NOW());

-- Log table: every time an event fires, it writes a row here.
-- Lets us SEE events running, which is otherwise invisible.
DROP TABLE IF EXISTS event_log;
CREATE TABLE event_log (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    message     VARCHAR(255),
    logged_at   DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Summary table: kept up-to-date by a recurring event.
DROP TABLE IF EXISTS orders_summary;
CREATE TABLE orders_summary (
    total_orders  INT NOT NULL DEFAULT 0,
    total_amount  DECIMAL(12,2) NOT NULL DEFAULT 0,
    refreshed_at  DATETIME DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO orders_summary (total_orders, total_amount)
VALUES (0, 0);

-- Wipe any leftover events from previous runs of this tutorial.
-- (See Section 4 — DROP EVENT — for the syntax.)
DROP EVENT IF EXISTS orders_archive_old_rows;
DROP EVENT IF EXISTS orders_refresh_summary;
DROP EVENT IF EXISTS orders_archive_24h;
DROP EVENT IF EXISTS orders_archive_12h;
DROP EVENT IF EXISTS orders_archive_2h;
DROP EVENT IF EXISTS orders_one_off_greet;
DROP EVENT IF EXISTS orders_archive_every_minute;

-- Reset summary to a known state
UPDATE orders_summary SET total_orders = 0, total_amount = 0;

-- Clear the log so each run starts fresh
TRUNCATE TABLE event_log;