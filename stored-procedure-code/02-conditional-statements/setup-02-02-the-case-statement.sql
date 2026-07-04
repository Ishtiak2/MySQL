-- Section 2. Conditional Statements
-- Setup under § 2.2 — The CASE statement
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE stock_status(IN p_id INT)
BEGIN
    DECLARE v_stock INT;
    DECLARE v_status VARCHAR(20);

    SELECT stock INTO v_stock FROM products WHERE id = p_id;

    CASE v_stock
        WHEN 0      THEN SET v_status = 'Out of stock';
        WHEN 1      THEN SET v_status = 'Almost gone';
        WHEN 2      THEN SET v_status = 'Almost gone';
        WHEN 3      THEN SET v_status = 'Almost gone';
        WHEN 100    THEN SET v_status = 'Pile!';
        ELSE             SET v_status = 'In stock';
    END CASE;

    SELECT p_id AS product_id, v_stock AS stock, v_status AS status;
END;
CALL stock_status(1);   -- 100 -> Pile!
CALL stock_status(2);   -- 500 -> In stock
CALL stock_status(3);   -- 25  -> In stock
