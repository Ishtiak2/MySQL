-- Section 1. Basic MySQL Stored Procedures
-- Setup under § 1.7 — Altering a Stored Procedure
-- Source: MySQL-Stored-Procedures.md

-- Step 1: drop the old version
DROP PROCEDURE IF EXISTS find_products_by_min_price;

-- Step 2: recreate with a new body (now also returning stock)

CREATE PROCEDURE find_products_by_min_price(IN min_price DECIMAL(10,2))
BEGIN
    SELECT name, price, stock
    FROM products
    WHERE price >= min_price
    ORDER BY price;
END;
CALL find_products_by_min_price(20.00);
