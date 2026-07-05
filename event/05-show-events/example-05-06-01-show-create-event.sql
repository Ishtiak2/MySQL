-- 05-show-events/example-05-06-01-show-create-event.sql
-- Section 5.6 — SHOW CREATE EVENT — see the exact definition
-- Always run this BEFORE dropping an event you might want to re-create.

-- First, make sure the event exists. Re-create it if not.
DROP EVENT IF EXISTS orders_refresh_summary;
CREATE EVENT orders_refresh_summary
    ON SCHEDULE EVERY 1 MINUTE
    STARTS CURRENT_TIMESTAMP
DO
    INSERT INTO event_log (message)
    VALUES (CONCAT('orders_refresh_summary ran at ', NOW()));

-- Now show the exact statement you'd use to re-create it
SHOW CREATE EVENT orders_refresh_summary;