-- Section 8. Transactions in Stored Procedures
-- Setup under § 8.9 — Common gotchas
-- Source: MySQL-Stored-Procedures.md

DECLARE EXIT HANDLER FOR 1213          -- or: FOR SQLEXCEPTION
BEGIN
    ROLLBACK;
    -- Optionally: retry
    RESIGNAL;
END;
