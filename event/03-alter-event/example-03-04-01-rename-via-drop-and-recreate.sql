-- 03-alter-event/example-03-04-01-rename-via-drop-and-recreate.sql
-- Section 3.4 — Renaming an event
-- MySQL has no RENAME EVENT, so the trick is DROP + CREATE.

USE event_demo;

DROP EVENT IF EXISTS orders_archive_2h;

CREATE EVENT orders_archive_two_hour_window
    ON SCHEDULE EVERY 1 MINUTE
    ENDS   CURRENT_TIMESTAMP + INTERVAL 2 HOUR
DO
    INSERT INTO event_log (message)
    VALUES (CONCAT('orders_archive_two_hour_window fired at ', NOW()));

-- The old name is gone, the new name is here:
SHOW EVENTS FROM event_demo LIKE 'orders_archive%';