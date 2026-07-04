-- Section 2. Conditional Statements
-- Example 2.2.2 — searched CASE (compare conditions)
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE stock_band(IN p_id INT)
BEGIN
    DECLARE v_stock INT;
    DECLARE v_band VARCHAR(20);

    SELECT stock INTO v_stock FROM products WHERE id = p_id;

    CASE
        WHEN v_stock IS NULL     THEN SET v_band = 'Unknown product';
        WHEN v_stock = 0         THEN SET v_band = 'Out of stock';
        WHEN v_stock < 10        THEN SET v_band = 'Low';
        WHEN v_stock BETWEEN 10 AND 100 THEN SET v_band = 'Medium';
        ELSE                          SET v_band = 'High';
    END CASE;

    SELECT p_id AS product_id, v_stock AS stock, v_band AS band;
END;
CALL stock_band(4);   -- 10 stock  -> Medium
CALL stock_band(2);   -- 500 stock -> High
CALL stock_band(3);   -- 25 stock  -> Medium
