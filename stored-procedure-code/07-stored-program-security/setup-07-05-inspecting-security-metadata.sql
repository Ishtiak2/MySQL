-- Section 7. Stored Program Security
-- Setup under § 7.5 — Inspecting security metadata
-- Source: MySQL-Stored-Procedures.md

-- The DEFINER and SQL SECURITY for a routine
SHOW CREATE PROCEDURE audit_log\G
SHOW CREATE FUNCTION  get_my_orders\G

-- Search by DEFINER
SELECT ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE, DEFINER, SECURITY_TYPE
FROM   information_schema.ROUTINES
WHERE  ROUTINE_SCHEMA = 'sp_demo';

-- Who has EXECUTE on a routine?
SELECT GRANTEE, PRIVILEGE_TYPE, IS_GRANTABLE
FROM   information_schema.SCHEMA_PRIVILEGES
WHERE  TABLE_SCHEMA  = 'sp_demo'
  AND  PRIVILEGE_TYPE = 'EXECUTE';
