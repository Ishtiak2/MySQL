-- Section 7. Stored Program Security
-- Example 7.2.2 — INVOKER security
-- Source: MySQL-Stored-Procedures.md

CREATE DEFINER = 'admin'@'localhost'
    FUNCTION get_my_orders(p_customer_id INT)
    RETURNS INT
    SQL SECURITY INVOKER
    READS SQL DATA
BEGIN
    DECLARE v_n INT;
    SELECT COUNT(*) INTO v_n FROM orders WHERE customer_id = p_customer_id;
    RETURN v_n;
END;