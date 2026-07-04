-- Section 4. Error Handling
-- Setup under § 4.5 — SIGNAL
-- Source: MySQL-Stored-Procedures.md

SIGNAL SQLSTATE { VALUE '45000' | sqlstate_literal }
    SET MESSAGE_TEXT  = 'your message here',
        MYSQL_ERRNO   = <number>,    -- optional
        SCHEMA_NAME   = '...',       -- optional
        TABLE_NAME    = '...'        -- optional
;
