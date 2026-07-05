-- 02-create-event/example-02-04-01-starts-and-ends-two-hour-window.sql
-- Section 2.5 — Recurring event with STARTS … ENDS …
-- Runs every minute for 2 hours, then stops on its own.

USE event_demo;

DROP EVENT IF EXISTS orders_archive_2h;

CREATE EVENT orders_archive_2h
    ON SCHEDULE EVERY 1 MINUTE
    STARTS CURRENT_TIMESTAMP
    ENDS   CURRENT_TIMESTAMP + INTERVAL 2 HOUR
    COMMENT 'Run every minute for 2 hours, then stop on its own'
DO
    INSERT INTO event_log (message)
    VALUES (CONCAT('orders_archive_2h fired at ', NOW()));

SHOW CREATE EVENT orders_archive_2h;