-- Section 6. Stored Functions
-- Example 6.1.4 — function with conditional logic
-- Source: MySQL-Stored-Procedures.md

CREATE FUNCTION stock_label(p_stock INT)
RETURNS VARCHAR(20)
    DETERMINISTIC
BEGIN
    IF p_stock IS NULL THEN
        RETURN 'Unknown';
    ELSEIF p_stock = 0 THEN
        RETURN 'Out of stock';
    ELSEIF p_stock < 25 THEN
        RETURN 'Low';
    ELSEIF p_stock < 100 THEN
        RETURN 'Medium';
    ELSE
        RETURN 'High';
    END IF;
END;
SELECT id, name, stock, stock_label(stock) AS label FROM products;
