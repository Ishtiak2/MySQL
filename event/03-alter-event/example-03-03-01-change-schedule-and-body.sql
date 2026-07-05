-- 03-alter-event/example-03-03-01-change-schedule-and-body.sql
-- Section 3.3 — Changing the schedule / body
-- Only the parts you list change; everything else stays the same.

USE event_demo;

-- Change the schedule from 1 MINUTE to 30 SECOND
ALTER EVENT orders_refresh_summary
    ON SCHEDULE EVERY 30 SECOND;

-- Replace the body
ALTER EVENT orders_refresh_summary
DO
    INSERT INTO event_log (message) VALUES ('New body — still ticking');

-- Change schedule AND body AND comment at once
ALTER EVENT orders_refresh_summary
    ON SCHEDULE EVERY 2 MINUTE
    COMMENT 'Slower, leaner body'
DO
    INSERT INTO event_log (message)
    VALUES (CONCAT('Refreshed at ', NOW()));

SHOW CREATE EVENT orders_refresh_summary;