-- 04-drop-event/example-04-02-01-drop-event-if-exists.sql
-- Section 4.2 — IF EXISTS to avoid errors
-- Without IF EXISTS, dropping a missing event throws ERROR 1304.
-- With IF EXISTS, the statement is a no-op when the event isn't there.

USE event_demo;

-- 1. This is safe — works whether or not the event exists.
DROP EVENT IF EXISTS orders_refresh_summary;

-- 2. This would throw without IF EXISTS:
--    DROP EVENT orders_refresh_summary;
--    ERROR 1304 (ER_SP_DOES_NOT_EXIST): Event 'orders_refresh_summary' does not exist

-- Nothing to show afterwards — both runs ended with the event gone.
SHOW EVENTS FROM event_demo LIKE 'orders_refresh_summary';