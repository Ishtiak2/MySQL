-- Section 8. Transactions in Stored Procedures
-- Setup under § 8.6 — Combining transactions with error handlers
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE transfer_funds_safe(
    IN p_from INT,
    IN p_to   INT,
    IN p_amt  DECIMAL(12,2)
)
BEGIN
    DECLARE v_bal DECIMAL(12,2);

    -- Generic error handler -> roll back, then re-raise
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE accounts SET bal = bal - p_amt WHERE id = p_from;

    -- Defensive check: did the row actually update?
    SELECT bal INTO v_bal FROM accounts WHERE id = p_from;
    IF v_bal < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;

    UPDATE accounts SET bal = bal + p_amt WHERE id = p_to;

    COMMIT;
END;