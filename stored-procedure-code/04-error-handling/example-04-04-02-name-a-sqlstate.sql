-- Section 4. Error Handling
-- Example 4.4.2 — name a SQLSTATE
-- Source: MySQL-Stored-Procedures.md

DECLARE out_of_range CONDITION FOR SQLSTATE '45000';
DECLARE EXIT HANDLER FOR out_of_range
    SELECT 'Out of range!' AS msg;
