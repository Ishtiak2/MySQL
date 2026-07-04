-- Section 4. Error Handling
-- Example 4.5.3 — signal within a handler
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE report_duplicate()
BEGIN
    DECLARE EXIT HANDLER FOR 1062
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Could not insert duplicate row',
                MYSQL_ERRNO  = 9999;

    INSERT INTO products (id, name, price) VALUES (1, 'Dup', 1.00);
END;
CALL report_duplicate();   -- raises MYSQL_ERRNO = 9999
