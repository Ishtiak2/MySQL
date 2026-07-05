-- 03-alter-event/example-03-01-01-disable-an-event.sql
-- Section 3.1 — Disabling an event (does NOT delete it)

USE event_demo;

-- Make sure the event exists so disabling it is meaningful.
-- (00-setup.sql dropped it; create it here if you want to disable something.)
DROP EVENT IF EXISTS orders_refresh_summary;
CREATE EVENT orders_refresh_summary
    ON SCHEDULE EVERY 1 MINUTE
DO
    INSERT INTO event_log (message) VALUES ('refresh — enabled');

ALTER EVENT orders_refresh_summary DISABLE;

-- Confirm
SHOW EVENTS FROM event_demo LIKE 'orders_refresh_summary';