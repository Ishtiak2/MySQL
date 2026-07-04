-- Section 7. Stored Program Security
-- Setup under § 7.2 — Creating with a specific DEFINER and SQL SECURITY
-- Source: MySQL-Stored-Procedures.md

CREATE
    [DEFINER = { user | CURRENT_USER | CURRENT_ROLE }]
    PROCEDURE | FUNCTION
    sp_name(...)
    ...
    [SQL SECURITY { DEFINER | INVOKER } ]
    ...
