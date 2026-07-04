-- Section 8. Transactions in Stored Procedures
-- Setup under § 8.5 — Your first transactional procedure
-- Source: MySQL-Stored-Procedures.md

DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
    id    INT PRIMARY KEY,
    name  VARCHAR(50),
    bal   DECIMAL(12,2) NOT NULL DEFAULT 0
);
INSERT INTO accounts VALUES (1, 'Alice', 100.00), (2, 'Bob', 100.00);
