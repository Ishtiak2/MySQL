-- Section 3. Loops
-- Setup under § 3.4 — LEAVE statement
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE first_three_in_stock(OUT p_result VARCHAR(200))
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_n   INT;
    DECLARE v_list VARCHAR(200) DEFAULT '';

    DECLARE cur CURSOR FOR SELECT n FROM numbers WHERE n <= 5 ORDER BY n;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_n;
        IF v_done THEN
            LEAVE read_loop;        -- <-- exit early
        END IF;
        IF v_n > 3 THEN
            SET v_done = TRUE;
            LEAVE read_loop;        -- <-- exit early
        END IF;
        SET v_list = CONCAT(v_list, IF(v_list='','',','), v_n);
    END LOOP;
    CLOSE cur;

    SET p_result = v_list;
END;
CALL first_three_in_stock(@r); SELECT @r;   -- "1,2,3"
