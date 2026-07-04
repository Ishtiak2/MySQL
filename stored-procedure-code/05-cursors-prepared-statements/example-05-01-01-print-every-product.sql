-- Section 5. Cursors and Prepared Statements
-- Example 5.1.1 — print every product
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE list_products()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id   INT;
    DECLARE v_name VARCHAR(100);
    DECLARE v_price DECIMAL(10,2);

    DECLARE cur CURSOR FOR
        SELECT id, name, price FROM products ORDER BY id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur;
    walk: LOOP
        FETCH cur INTO v_id, v_name, v_price;
        IF v_done THEN
            LEAVE walk;
        END IF;
        SELECT v_id AS id, v_name AS name, v_price AS price;
    END LOOP walk;
    CLOSE cur;
END;
CALL list_products();
