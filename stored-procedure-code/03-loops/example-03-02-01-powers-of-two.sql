-- Section 3. Loops
-- Example 3.2.1 — powers of two
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE powers_of_two(IN p_max INT)
BEGIN
    DECLARE v_n INT DEFAULT 1;

    DROP TEMPORARY TABLE IF EXISTS powers;
    CREATE TEMPORARY TABLE powers (value INT);

    REPEAT
        INSERT INTO powers VALUES (v_n);
        SET v_n = v_n * 2;
    UNTIL v_n > p_max
    END REPEAT;

    SELECT * FROM powers;
END;
CALL powers_of_two(100);   -- 1, 2, 4, 8, 16, 32, 64, 128
