-- Section 5. Cursors and Prepared Statements
-- Example 5.1.3 — cursor that calculates a running total
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE reorder_report(IN p_threshold INT)
BEGIN
    -- Products with stock < p_threshold, listed with their suggested re-order qty.
    DECLARE v_done   INT DEFAULT FALSE;
    DECLARE v_id     INT;
    DECLARE v_name   VARCHAR(100);
    DECLARE v_stock  INT;
    DECLARE v_reorder INT;

    DROP TEMPORARY TABLE IF EXISTS reorder_list;
    CREATE TEMPORARY TABLE reorder_list (
        id        INT,
        name      VARCHAR(100),
        stock     INT,
        reorder_to INT
    );

    DECLARE cur CURSOR FOR
        SELECT id, name, stock FROM products
        WHERE stock < p_threshold
        ORDER BY stock ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur;
    fill: LOOP
        FETCH cur INTO v_id, v_name, v_stock;
        IF v_done THEN
            LEAVE fill;
        END IF;
        SET v_reorder = GREATEST(100 - v_stock, 0);
        INSERT INTO reorder_list VALUES (v_id, v_name, v_stock, v_reorder);
    END LOOP fill;
    CLOSE cur;

    SELECT * FROM reorder_list ORDER BY stock;
END;
CALL reorder_report(50);
