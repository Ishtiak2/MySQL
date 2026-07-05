-- 02-create-event/example-02-03-01-daily-at-3am-archive-old-orders.sql
-- Section 2.4 — Recurring event at a specific clock time
-- Runs every night at 03:00 (next one is tomorrow at 03:00).
-- STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 3 HOUR) = "tomorrow 03:00".

USE event_demo;

DROP EVENT IF EXISTS orders_archive_old_rows;

CREATE EVENT orders_archive_old_rows
    ON SCHEDULE EVERY 1 DAY
    STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 3 HOUR)
    COMMENT 'Archive orders older than 7 days, nightly at 03:00'
DO
    -- For the tutorial we use 0 seconds so the demo produces output on demand.
    DELETE FROM orders
    WHERE created_at < NOW() - INTERVAL 0 SECOND;

    INSERT INTO event_log (message)
    VALUES (CONCAT('orders_archive_old_rows fired at ', NOW()));

SHOW CREATE EVENT orders_archive_old_rows;