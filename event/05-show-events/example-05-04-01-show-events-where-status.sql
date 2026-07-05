-- 05-show-events/example-05-04-01-show-events-where-status.sql
-- Section 5.4 — SHOW EVENTS WHERE … filtering by status / type

-- All enabled events
SHOW EVENTS FROM event_demo WHERE Status = 'ENABLED';

-- All disabled events
SHOW EVENTS FROM event_demo WHERE Status = 'DISABLED';

-- Recurring events only
SHOW EVENTS FROM event_demo WHERE Type = 'RECURRING';

-- One-time events only
SHOW EVENTS FROM event_demo WHERE Type = 'ONE TIME';