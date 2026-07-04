-- Section 7. Stored Program Security
-- Example 7.2.3 — `ALTER` for an existing program
-- Source: MySQL-Stored-Procedures.md

ALTER PROCEDURE audit_log
    SQL SECURITY DEFINER
    COMMENT 'Writes audit rows as the definer';

ALTER FUNCTION get_my_orders
    SQL SECURITY INVOKER;
