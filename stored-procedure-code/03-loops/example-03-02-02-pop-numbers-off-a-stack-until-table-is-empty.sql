-- Section 3. Loops
-- Example 3.2.2 — pop numbers off a stack (until table is empty)
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE drain_numbers()
BEGIN
    DECLARE v_n INT;

    REPEAT
        SELECT n INTO v_n FROM numbers ORDER BY n DESC LIMIT 1;
        IF v_n IS NOT NULL THEN
            DELETE FROM numbers WHERE n = v_n;
            SELECT CONCAT('removed ', v_n) AS log;
        END IF;
    UNTIL v_n IS NULL
    END REPEAT;

    SELECT 'all gone' AS done;
END;
CALL drain_numbers();
SELECT COUNT(*) AS remaining FROM numbers;
