-- Section 3. Loops
-- Example 3.3.1 — factorial (with LEAVE)
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE factorial(IN p_n INT, OUT p_result BIGINT)
BEGIN
    DECLARE v_i  INT DEFAULT 1;
    SET p_result = 1;

    my_loop: LOOP
        IF v_i > p_n THEN
            LEAVE my_loop;
        END IF;
        SET p_result = p_result * v_i;
        SET v_i = v_i + 1;
    END LOOP my_loop;
END;
CALL factorial(5,  @f); SELECT @f;   -- 120
CALL factorial(10, @f); SELECT @f;   -- 3628800
