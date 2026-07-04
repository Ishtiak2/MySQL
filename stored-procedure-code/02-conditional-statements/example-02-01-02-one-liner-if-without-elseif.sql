-- Section 2. Conditional Statements
-- Example 2.1.2 — one-liner IF without ELSEIF
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE warn_if_out_of_stock(IN p_id INT)
BEGIN
    DECLARE v_stock INT;

    SELECT stock INTO v_stock FROM products WHERE id = p_id;

    IF v_stock = 0 THEN
        SELECT 'OUT OF STOCK!' AS warning;
    END IF;
END;
CALL warn_if_out_of_stock(3);   -- Backpack has stock, no message returned
