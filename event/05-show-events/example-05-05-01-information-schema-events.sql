-- 05-show-events/example-05-05-01-information-schema-events.sql
-- Section 5.5 — information_schema.events — the full view
-- Includes the event BODY (EVENT_DEFINITION) and every timing column.

SELECT
    EVENT_SCHEMA,
    EVENT_NAME,
    EVENT_TYPE,            -- 'ONE TIME' or 'RECURRING'
    STATUS,                -- 'ENABLED' / 'DISABLED' / 'SLAVESIDE DISABLED'
    INTERVAL_VALUE,
    INTERVAL_FIELD,
    STARTS,
    ENDS,
    EXECUTE_AT,
    EVENT_DEFINITION       -- the SQL inside the DO
FROM information_schema.events
WHERE EVENT_SCHEMA = 'event_demo'
ORDER BY EVENT_NAME;