-- Section 6. Stored Functions
-- Example 6.1.2 — function that takes a parameter
-- Source: MySQL-Stored-Procedures.md

CREATE FUNCTION price_with_tax(p_price DECIMAL(10,2), p_rate DECIMAL(4,2))
RETURNS DECIMAL(10,2)
    DETERMINISTIC
BEGIN
    RETURN ROUND(p_price * (1 + p_rate), 2);
END;
SELECT price_with_tax(100.00, 0.07) AS with_tax;
