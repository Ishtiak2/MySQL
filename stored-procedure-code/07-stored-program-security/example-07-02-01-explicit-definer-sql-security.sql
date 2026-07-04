-- Section 7. Stored Program Security
-- Example 7.2.1 — explicit DEFINER + SQL SECURITY
-- Source: MySQL-Stored-Procedures.md

-- Logged in as root

CREATE DEFINER = 'admin'@'localhost'
    PROCEDURE audit_log(IN p_msg VARCHAR(200))
    SQL SECURITY DEFINER
BEGIN
    INSERT INTO audit_log(when_at, msg, by_user)
    VALUES (NOW(), p_msg, CURRENT_USER());
END;