-- Section 4. Error Handling
-- Example 4.6.2 — change the error message then resignal
-- Source: MySQL-Stored-Procedures.md

DECLARE CONTINUE HANDLER FOR 1062
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Friendly message for the user';

    -- ^ that swallows the duplicate entry error;
    --   if you'd rather KEEP the original error but with a friendlier message:
    RESIGNAL SET MESSAGE_TEXT = 'Friendly wrapper around the duplicate-key error';
END;
