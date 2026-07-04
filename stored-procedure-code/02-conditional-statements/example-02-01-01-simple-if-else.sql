-- Section 2. Conditional Statements
-- Example 2.1.1 — simple IF / ELSE
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE label_product(IN p_id INT)
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_label VARCHAR(20);

    SELECT price INTO v_price FROM products WHERE id = p_id;

    IF v_price IS NULL THEN
        SET v_label = 'Unknown product';
    ELSEIF v_price < 5 THEN
        SET v_label = 'Cheap';
    ELSEIF v_price < 25 THEN
        SET v_label = 'Mid-range';
    ELSE
        SET v_label = 'Premium';
    END IF;

    SELECT p_id AS product_id, v_price AS price, v_label AS label;
END;
CALL label_product(1);   -- Notebook (4.50)  -> Cheap
CALL label_product(4);   -- Headphones (49)  -> Premium
CALL label_product(99);  -- does not exist
