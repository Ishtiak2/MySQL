-- Section 8. Transactions in Stored Procedures
-- Setup under § 8.2 — Engine matters: InnoDB vs MyISAM
-- Source: MySQL-Stored-Procedures.md

-- Confirm engine
SELECT ENGINE FROM information_schema.TABLES
WHERE  TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'products';
-- must say 'InnoDB'
