-- Section 4. Error Handling
-- Example 4.4.1 — name error 1062
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE safe_insert_named(IN p_name VARCHAR(100), IN p_price DECIMAL(10,2))
BEGIN
    DECLARE duplicate_key CONDITION FOR 1062;

    DECLARE EXIT HANDLER FOR duplicate_key
        SELECT CONCAT(p_name, ' already exists (via named condition)') AS msg;

    INSERT INTO products (name, price) VALUES (p_name, p_price);
    SELECT CONCAT('Inserted ', p_name) AS ok;
END;
CALL safe_insert_named('Keyboard', 25.00);
CALL safe_insert_named('Keyboard', 25.00);
