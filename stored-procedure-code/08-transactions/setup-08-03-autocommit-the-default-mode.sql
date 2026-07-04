-- Section 8. Transactions in Stored Procedures
-- Setup under § 8.3 — Autocommit — the default mode
-- Source: MySQL-Stored-Procedures.md

SELECT @@autocommit;            -- 1 = on (default), 0 = off

SET autocommit = 0;             -- session level
SET SESSION autocommit = 0;     -- same thing, explicit
SET GLOBAL  autocommit = 0;     -- affects all NEW connections (SUPER privilege)
