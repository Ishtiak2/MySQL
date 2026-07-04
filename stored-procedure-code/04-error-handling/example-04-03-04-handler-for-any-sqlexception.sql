-- Section 4. Error Handling
-- Example 4.3.4 — handler for any `SQLEXCEPTION`
-- Source: MySQL-Stored-Procedures.md

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    ROLLBACK;             -- (we'll talk about transactions in Section 8)
    RESIGNAL;             -- <-- see 4.6
END;
