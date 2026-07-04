-- Section 4. Error Handling
-- Setup under § 4.3 — DECLARE ... HANDLER
-- Source: MySQL-Stored-Procedures.md

DECLARE handler_action HANDLER
    FOR condition_value [, condition_value] ...
    handler_statement;
