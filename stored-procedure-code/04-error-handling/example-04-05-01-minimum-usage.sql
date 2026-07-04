-- Section 4. Error Handling
-- Example 4.5.1 — minimum usage
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE divide_check(IN a INT, IN b INT)
BEGIN
    IF b = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Division by zero is not allowed';
    END IF;

    SELECT a / b AS result;
END;
CALL divide_check(10, 2);   -- 5
CALL divide_check(10, 0);   -- ERROR 1644: Division by zero is not allowed
