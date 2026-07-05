-- 02-create-event/example-02-05-01-keep-after-fire-on-completion-preserve.sql
-- Section 2.6 — ON COMPLETION PRESERVE
-- One-time event that stays around (disabled) after it fires.

USE event_demo;

DROP EVENT IF EXISTS orders_one_off_greet;

CREATE EVENT orders_one_off_greet
    ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 30 SECOND
    ON COMPLETION PRESERVE
    COMMENT 'Keep me after I fire'
DO
    INSERT INTO event_log (message) VALUES ('I fired once and lived to tell about it');

SHOW CREATE EVENT orders_one_off_greet;

-- After it fires, you can still find it (now disabled):
--   SHOW EVENTS FROM event_demo LIKE 'orders_one_off%';