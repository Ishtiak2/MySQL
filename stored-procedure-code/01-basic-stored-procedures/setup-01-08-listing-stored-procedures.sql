-- Section 1. Basic MySQL Stored Procedures
-- Setup under § 1.8 — Listing Stored Procedures
-- Source: MySQL-Stored-Procedures.md

-- Show all procedures in the current database
SHOW PROCEDURE STATUS WHERE Db = DATABASE();

-- Show the source / definition of one procedure
SHOW CREATE PROCEDURE get_all_products;
