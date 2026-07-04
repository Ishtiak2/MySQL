-- Section 5. Cursors and Prepared Statements
-- Example 5.2.2 — inside a stored procedure
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE get_products_above(IN p_min DECIMAL(10,2))
BEGIN
    -- Prepared statements in stored programs must NOT clash with other
    -- statements or user variables; pick a clear name.
    PREPARE stmt FROM 'SELECT id, name, price
                       FROM products
                       WHERE price > ?
                       ORDER BY price';

    EXECUTE stmt USING p_min;        -- <-- IN parameter works as a USAGE target
    DEALLOCATE PREPARE stmt;
END;
CALL get_products_above(20);
