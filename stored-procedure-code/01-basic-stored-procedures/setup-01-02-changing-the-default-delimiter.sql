-- Section 1. Basic MySQL Stored Procedures
-- Setup under § 1.2 — Changing the Default Delimiter
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE my_proc()
BEGIN
   -- these semicolons are now just statement separators,
   -- NOT the end of the CREATE PROCEDURE command
   SELECT 1;
   SELECT 2;
END;
DELIMITER ;   -- back to the normal ';' for everything else
