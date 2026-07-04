-- Section 8. Transactions in Stored Procedures
-- Setup under § 8.7 — Savepoints — partial rollback inside one transaction
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE three_steps()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT after_step1;   -- undo step 2/3, keep step 1
        -- (no RESIGNAL: the procedure succeeded from its own point of view)
    END;

    START TRANSACTION;

    -- Step 1: guaranteed to land
    INSERT INTO accounts(id, name, bal) VALUES (3, 'Carol', 0);

    SAVEPOINT after_step1;

    -- Step 2: might fail (e.g. violates a unique key)
    UPDATE accounts SET bal = bal + 100 WHERE id = 3;

    -- Step 3
    UPDATE accounts SET bal = bal + 1   WHERE id = 1;

    COMMIT;
END;