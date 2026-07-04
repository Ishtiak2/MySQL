-- Section 6. Stored Functions
-- Example 6.1.3 — function that reads from a table
-- Source: MySQL-Stored-Procedures.md

CREATE FUNCTION get_product_name(p_id INT)
RETURNS VARCHAR(100)
    READS SQL DATA
BEGIN
    DECLARE v_name VARCHAR(100);

    SELECT name INTO v_name FROM products WHERE id = p_id;

    RETURN IFNULL(v_name, 'NOT FOUND');
END;
SELECT id, get_product_name(id) AS name FROM products;
