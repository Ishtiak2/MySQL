-- Section 4. Error Handling
-- Example 4.5.2 — `SIGNAL` + a named condition
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE raise_only_adults(IN p_age INT)
BEGIN
    DECLARE too_young CONDITION FOR SQLSTATE '45000';

    IF p_age < 18 THEN
        SIGNAL too_young
            SET MESSAGE_TEXT = 'Age must be 18 or older',
                MYSQL_ERRNO  = 5001;
    END IF;

    SELECT 'Welcome!' AS greeting;
END;
CALL raise_only_adults(21);   -- Welcome!
CALL raise_only_adults(15);   -- ERROR 5001: Age must be 18 or older
