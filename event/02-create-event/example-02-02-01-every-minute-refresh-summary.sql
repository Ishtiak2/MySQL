-- 02-create-event/example-02-02-01-every-minute-refresh-summary.sql
-- Section 2.3 — Recurring event (EVERY …)
-- Refreshes the orders_summary dashboard every minute.
-- Wait a minute or two after running, then SELECT from orders_summary.

USE event_demo;

DROP EVENT IF EXISTS orders_refresh_summary;

CREATE EVENT orders_refresh_summary
    ON SCHEDULE EVERY 1 MINUTE
    STARTS CURRENT_TIMESTAMP
    COMMENT 'Recompute orders_summary every minute'
DO
    -- Recompute the totals each time we fire
    INSERT INTO orders_summary (total_orders, total_amount)
    SELECT COUNT(*), COALESCE(SUM(amount), 0)
    FROM orders
    ON DUPLICATE KEY UPDATE
        total_orders  = VALUES(total_orders),
        total_amount  = VALUES(total_amount);

    -- Heartbeat so we can see the event actually fired
    INSERT INTO event_log (message)
    VALUES (CONCAT('orders_refresh_summary ran at ', NOW()));

SHOW CREATE EVENT orders_refresh_summary;