-- Section 5. Cursors and Prepared Statements
-- Example 5.1.2 — build a comma-separated string of names
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE names_csv(OUT p_list VARCHAR(4000))
BEGIN
    DECLARE v_done  INT DEFAULT FALSE;
    DECLARE v_name  VARCHAR(100);
    DECLARE v_first INT DEFAULT TRUE;

    DECLARE cur CURSOR FOR SELECT name FROM products ORDER BY id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET p_list = '';

    OPEN cur;
    walk: LOOP
        FETCH cur INTO v_name;
        IF v_done THEN
            LEAVE walk;
        END IF;
        IF v_first THEN
            SET p_list = v_name;
            SET v_first = FALSE;
        ELSE
            SET p_list = CONCAT(p_list, ',', v_name);
        END IF;
    END LOOP walk;
    CLOSE cur;
END;
CALL names_csv(@list); SELECT @list;
