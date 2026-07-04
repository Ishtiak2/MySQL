-- Section 7. Stored Program Security
-- Setup under § 7.8 — Quick summary — DEFINER vs INVOKER
-- Source: MySQL-Stored-Procedures.md

SELECT ROUTINE_NAME, ROUTINE_TYPE, DEFINER, SECURITY_TYPE
FROM   information_schema.ROUTINES
WHERE  ROUTINE_SCHEMA = DATABASE()
ORDER  BY ROUTINE_TYPE, ROUTINE_NAME;
