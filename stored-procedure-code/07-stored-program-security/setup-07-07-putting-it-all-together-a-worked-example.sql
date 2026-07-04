-- Section 7. Stored Program Security
-- Setup under § 7.7 — Putting it all together — a worked example
-- Source: MySQL-Stored-Procedures.md

-- 0. Make sure the schema + users exist
CREATE DATABASE IF NOT EXISTS sp_demo;
USE sp_demo;

DROP TABLE IF EXISTS audit_log;
CREATE TABLE audit_log (
    id     INT PRIMARY KEY AUTO_INCREMENT,
    when_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    msg    VARCHAR(200),
    by_user VARCHAR(100)
);

-- (Already created above, but re-stated for completeness)
CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'admin_pw';
GRANT ALL ON sp_demo.* TO 'admin'@'localhost';

CREATE USER IF NOT EXISTS 'app_user'@'%'      IDENTIFIED BY 'user_pw';

-- 1. As admin: create the routine

CREATE DEFINER = 'admin'@'localhost'
    PROCEDURE log_event(IN p_msg VARCHAR(200))
    SQL SECURITY DEFINER
BEGIN
    INSERT INTO audit_log (msg, by_user)
    VALUES (p_msg, CURRENT_USER());
END;
-- 2. As admin: let app_user call it
GRANT EXECUTE ON PROCEDURE sp_demo.log_event TO 'app_user'@'%';

-- 3. Switch to app_user and call it
--    (in MySQL Workbench: "MySQL Connections -> New -> app_user")
CALL sp_demo.log_event('first  call from app_user');
CALL sp_demo.log_event('second call from app_user');

-- 4. As admin again: check the audit table
SELECT * FROM sp_demo.audit_log;
-- Note: `by_user` is 'admin@localhost' even though the *invoking* session was app_user,
--       because SQL SECURITY = DEFINER. That's the whole point.
