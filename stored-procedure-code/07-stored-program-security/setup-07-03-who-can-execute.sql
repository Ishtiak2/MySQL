-- Section 7. Stored Program Security
-- Setup under § 7.3 — Who can execute?
-- Source: MySQL-Stored-Procedures.md

-- Procedure
GRANT EXECUTE ON PROCEDURE sp_demo.audit_log TO 'app_user'@'%';

-- Function
GRANT EXECUTE ON FUNCTION  sp_demo.get_my_orders TO 'app_user'@'%';

-- All routines in a database
GRANT EXECUTE ON sp_demo.* TO 'app_user'@'%';
