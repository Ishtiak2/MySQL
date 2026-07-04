-- Section 5. Cursors and Prepared Statements
-- Example 5.2.3 — dynamic-table-style use (different `WHERE` clauses)
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE search_products(
    IN  p_name       VARCHAR(100),
    IN  p_min_price  DECIMAL(10,2),
    IN  p_max_price  DECIMAL(10,2),
    IN  p_order_by   VARCHAR(50)
)
BEGIN
    SET @sql = 'SELECT id, name, price, stock
                FROM products
                WHERE 1=1';

    IF p_name IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND name LIKE ?');
        SET @arg = CONCAT('%', p_name, '%');
    END IF;

    IF p_min_price IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND price >= ?');
        SET @min := p_min_price;
    END IF;

    IF p_max_price IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND price <= ?');
        SET @max := p_max_price;
    END IF;

    -- Order column name can't use ?, so we either whitelist it or fall back.
    IF p_order_by IN ('price', 'name', 'stock') THEN
        SET @sql = CONCAT(@sql, ' ORDER BY ', p_order_by);
    ELSE
        SET @sql = CONCAT(@sql, ' ORDER BY id');
    END IF;

    PREPARE stmt FROM @sql;

    -- The number of USING arguments must match the number of ? we added.
    IF p_name IS NOT NULL AND p_min_price IS NOT NULL AND p_max_price IS NOT NULL THEN
        EXECUTE stmt USING @arg, @min, @max;
    ELSEIF p_name IS NOT NULL AND p_min_price IS NOT NULL THEN
        EXECUTE stmt USING @arg, @min;
    ELSEIF p_name IS NOT NULL AND p_max_price IS NOT NULL THEN
        EXECUTE stmt USING @arg, @max;
    ELSEIF p_name IS NOT NULL THEN
        EXECUTE stmt USING @arg;
    ELSEIF p_min_price IS NOT NULL AND p_max_price IS NOT NULL THEN
        EXECUTE stmt USING @min, @max;
    ELSEIF p_min_price IS NOT NULL THEN
        EXECUTE stmt USING @min;
    ELSEIF p_max_price IS NOT NULL THEN
        EXECUTE stmt USING @max;
    ELSE
        EXECUTE stmt;
    END IF;

    DEALLOCATE PREPARE stmt;
END;
CALL search_products(NULL,     10,    NULL,  'price');
CALL search_products('Bag',    NULL,  50,    'name');
CALL search_products(NULL,     NULL,  NULL,  NULL);
