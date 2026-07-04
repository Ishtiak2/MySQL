-- Section 4. Error Handling
-- Example 4.3.2 — continue handler (skip the bad row)
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE average_price_above(IN min_price DECIMAL(10,2))
BEGIN
    DECLARE v_sum   DECIMAL(10,2) DEFAULT 0;
    DECLARE v_count INT           DEFAULT 0;
    DECLARE v_done  INT           DEFAULT FALSE;
    DECLARE v_n     VARCHAR(100);
    DECLARE v_p     DECIMAL(10,2);

    DECLARE cur CURSOR FOR
        SELECT name, price FROM products WHERE price >= min_price;

    -- 1325 = "No data – zero rows fetched, updated, or deleted"
    -- '02000' is the matching SQLSTATE for the same condition.
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur;
    read: LOOP
        FETCH cur INTO v_n, v_p;
        IF v_done THEN
            LEAVE read;
        END IF;
        SET v_sum   = v_sum + v_p;
        SET v_count = v_count + 1;
    END LOOP read;
    CLOSE cur;

    SELECT v_count       AS rows_used,
           v_sum         AS sum_prices,
           v_sum / NULLIF(v_count, 0) AS average_price;
END;
CALL average_price_above(10);   -- skips the cheap ones
