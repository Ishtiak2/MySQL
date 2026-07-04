-- Section 4. Error Handling
-- Setup under § 4.4 — DECLARE ... CONDITION
-- Source: MySQL-Stored-Procedures.md

DECLARE condition_name CONDITION FOR { SQLSTATE [VALUE] '5xxxxx' | mysql_error_code };
