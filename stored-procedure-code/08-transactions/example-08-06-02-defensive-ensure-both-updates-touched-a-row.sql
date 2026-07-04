-- Section 8. Transactions in Stored Procedures
-- Example 8.6.2 — defensive: ensure both updates touched a row
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE transfer_funds_v2(
    IN p_from INT,
    IN p_to   INT,
    IN p_amt  DECIMAL(12,2)
)
BEGIN
    DECLARE v_rows INT;
    DECLARE v_bal DECIMAL(12,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Sender
    UPDATE accounts SET bal = bal - p_amt WHERE id = p_from;
    SELECT ROW_COUNT() INTO v_rows;
    IF v_rows = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sender account not found';
    END IF;

    SELECT bal INTO v_bal FROM accounts WHERE id = p_from;
    IF v_bal < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;

    -- Receiver
    UPDATE accounts SET bal = bal + p_amt WHERE id = p_to;
    SELECT ROW_COUNT() INTO v_rows;
    IF v_rows = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Receiver account not found';
    END IF;

    COMMIT;
END;