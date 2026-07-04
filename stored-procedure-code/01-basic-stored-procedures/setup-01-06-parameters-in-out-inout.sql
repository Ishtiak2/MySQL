-- Section 1. Basic MySQL Stored Procedures
-- Setup under § 1.6 — Parameters (IN, OUT, INOUT)
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE find_products_by_min_price(IN min_price DECIMAL(10,2))
BEGIN
    SELECT name, price
    FROM products
    WHERE price >= min_price
    ORDER BY price;
END;
CALL find_products_by_min_price(10.00);
