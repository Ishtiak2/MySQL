-- Section 3. Loops
-- Example 3.1.2 — fill a new table with running totals
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE build_running_total()
BEGIN
    DROP TEMPORARY TABLE IF EXISTS running_totals;
    CREATE TEMPORARY TABLE running_totals (
        n        INT,
        cumulative INT
    );

    DECLARE v_i     INT DEFAULT 1;
    DECLARE v_total INT DEFAULT 0;

    WHILE v_i <= 10 DO
        SET v_total = v_total + v_i;
        INSERT INTO running_totals (n, cumulative) VALUES (v_i, v_total);
        SET v_i = v_i + 1;
    END WHILE;

    SELECT * FROM running_totals;
END;
CALL build_running_total();
