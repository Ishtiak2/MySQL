-- Section 8. Transactions in Stored Procedures
-- Setup under § 8.8 — Isolation levels — what other sessions see
-- Source: MySQL-Stored-Procedures.md

-- Affects the NEXT transaction only
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Or only inside this procedure
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
