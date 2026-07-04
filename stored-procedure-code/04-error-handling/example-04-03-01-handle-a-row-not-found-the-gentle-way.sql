-- Section 4. Error Handling
-- Example 4.3.1 — handle a "row not found" the gentle way
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE find_by_id(IN p_id INT)
BEGIN
    DECLARE v_name VARCHAR(100);

    -- When SELECT ... INTO returns nothing, set v_name to NULL
    -- instead of error 1325 (No data) or 1324 (Undeclared...)
    SELECT name INTO v_name FROM products WHERE id = p_id;

    SELECT IFNULL(v_name, 'NOT FOUND') AS name;
END;
CALL find_by_id(1);    -- Notebook
CALL find_by_id(99);   -- NOT FOUND
