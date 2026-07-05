-- 02-create-event/example-02-01-01-hello-world-one-time-event.sql
-- Section 2.2 — One-time event (AT …)
-- Run after 00-setup.sql. The scheduler must be ON (SET GLOBAL event_scheduler = ON;).
-- This event fires once, 30 seconds after creation, then is dropped automatically.

USE event_demo;

DROP EVENT IF EXISTS orders_one_off_greet;

CREATE EVENT orders_one_off_greet
    ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 30 SECOND
    ON COMPLETION NOT PRESERVE
    COMMENT 'My very first one-time event'
DO
    INSERT INTO event_log (message)
    VALUES (CONCAT('Hello! Fired at ', NOW()));

-- Show what we just created (use \G in an interactive client for vertical output)
SHOW CREATE EVENT orders_one_off_greet;

-- Wait until 30s have passed, then check event_log:
--   SELECT * FROM event_log ORDER BY id DESC;
-- (Uncomment to poll right here. Won't work in a non-interactive mysql client.)
-- SELECT id, message, logged_at FROM event_log ORDER BY id DESC;