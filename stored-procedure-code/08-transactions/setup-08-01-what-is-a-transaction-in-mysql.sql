-- Section 8. Transactions in Stored Procedures
-- Setup under § 8.1 — What is a "transaction" in MySQL?
-- Source: MySQL-Stored-Procedures.md

-- Confirm engine
SELECT ENGINE FROM information_schema.TABLES
WHERE  TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'products';
-- must say 'InnoDB'
