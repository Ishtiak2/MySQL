-- 03-alter-event/example-03-02-01-enable-an-event.sql
-- Section 3.2 — Enabling an event

USE event_demo;

-- Re-enable whatever example disabled the event
ALTER EVENT orders_refresh_summary ENABLE;

-- Confirm
SHOW EVENTS FROM event_demo LIKE 'orders_refresh_summary';

-- You can also enable + change schedule in one go:
-- ALTER EVENT orders_refresh_summary ENABLE ON SCHEDULE EVERY 5 MINUTE;