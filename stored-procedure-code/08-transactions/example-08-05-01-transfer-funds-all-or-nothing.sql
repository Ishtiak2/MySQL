-- Section 8. Transactions in Stored Procedures
-- Example 8.5.1 — transfer funds, all-or-nothing
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE transfer_funds(
    IN p_from INT,
    IN p_to   INT,
    IN p_amt  DECIMAL(12,2)
)
BEGIN
    -- 1. Input validation
    IF p_amt <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Amount must be positive';
    END IF;

    -- 2. Begin transaction
    START TRANSACTION;

    UPDATE accounts SET bal = bal - p_amt WHERE id = p_from;
    UPDATE accounts SET bal = bal + p_amt WHERE id = p_to;

    -- 3. Either keep both changes…
    COMMIT;
END;
-- Try it
CALL transfer_funds(1, 2, 25.00);
SELECT * FROM accounts;
-- Alice: 75.00, Bob: 125.00
