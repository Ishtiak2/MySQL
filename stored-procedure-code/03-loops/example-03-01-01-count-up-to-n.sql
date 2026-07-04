-- Section 3. Loops
-- Example 3.1.1 — count up to N
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE count_up(IN p_max INT)
BEGIN
    DECLARE v_i INT DEFAULT 1;

    WHILE v_i <= p_max DO
        SELECT v_i AS n;
        SET v_i = v_i + 1;
    END WHILE;
END;
CALL count_up(3);   -- returns 1, then 2, then 3 (three result sets)
