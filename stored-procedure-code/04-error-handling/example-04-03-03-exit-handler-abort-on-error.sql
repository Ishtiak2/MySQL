-- Section 4. Error Handling
-- Example 4.3.3 — exit handler (abort on error)
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE safe_insert(IN p_name VARCHAR(100), IN p_price DECIMAL(10,2))
BEGIN
    -- 1062 = Duplicate entry for a UNIQUE key
    DECLARE EXIT HANDLER FOR 1062
        SELECT CONCAT('Product "', p_name, '" already exists!') AS error;

    INSERT INTO products (name, price) VALUES (p_name, p_price);
    SELECT CONCAT('Inserted ', p_name) AS ok;
END;
CALL safe_insert('Mouse', 12.50);   -- Inserted Mouse
CALL safe_insert('Mouse', 12.50);   -- already exists! (handler fired)
