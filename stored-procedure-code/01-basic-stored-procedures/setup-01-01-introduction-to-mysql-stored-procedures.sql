-- Section 1. Basic MySQL Stored Procedures
-- Setup under § 1.1 — Introduction to MySQL Stored Procedures
-- Source: MySQL-Stored-Procedures.md

-- A procedure that returns a greeting

CREATE PROCEDURE say_hello()
BEGIN
    SELECT 'Hello from MySQL!' AS message;
END;
-- Run it
CALL say_hello();
