-- 04-drop-event/example-04-01-01-drop-an-event.sql
-- Section 4.1 — Dropping an event with DROP EVENT
-- This is permanent — the definition is gone.

USE event_demo;

-- Always SHOW CREATE EVENT first, in real life, so you can copy the definition
-- back later if you need it. (Uncomment if you want to see it.)
-- SHOW CREATE EVENT orders_refresh_summary\G

DROP EVENT orders_refresh_summary;

-- It is gone now:
SHOW EVENTS FROM event_demo LIKE 'orders_refresh_summary';
-- (empty result set)