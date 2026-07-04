-- Section 1. Basic MySQL Stored Procedures
-- Setup under § 1.5 — Variables
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE price_with_tax()
BEGIN
    DECLARE tax_rate DECIMAL(5,2) DEFAULT 0.07;  -- 7% tax
    DECLARE base_price DECIMAL(10,2);
    DECLARE final_price DECIMAL(10,2);

    SET base_price = 100.00;
    SET final_price = base_price * (1 + tax_rate);

    SELECT base_price AS base, final_price AS total_with_tax;
END;
CALL price_with_tax();
