-- Section 7. Stored Program Security
-- Setup under § 7.4 — Grant examples by user
-- Source: MySQL-Stored-Procedures.md

-- Create one admin who owns everything, plus two low-privilege callers.
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin_pw';
CREATE USER 'app_user'@'%'      IDENTIFIED BY 'user_pw';
CREATE USER 'guest'@'%'         IDENTIFIED BY 'guest_pw';

GRANT ALL ON sp_demo.* TO 'admin'@'localhost';

-- app_user: can run procedures, but not directly read products
GRANT EXECUTE ON sp_demo.* TO 'app_user'@'%';

-- guest: no privileges yet
