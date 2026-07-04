-- Section 5. Cursors and Prepared Statements
-- Example 5.1.4 — nested cursors (orders + items)
-- Source: MySQL-Stored-Procedures.md

-- Helper tables (one-to-many)
DROP TABLE IF EXISTS orders, order_items;
CREATE TABLE orders     (id INT PRIMARY KEY, customer VARCHAR(50));
CREATE TABLE order_items(order_id INT, product_id INT, qty INT);

INSERT INTO orders VALUES
 (1,'Alice'), (2,'Bob');

INSERT INTO order_items VALUES
 (1,1,2), (1,2,5),     -- Alice: 2 notebooks + 5 pens
 (2,4,1);              -- Bob:   1 headphones


CREATE PROCEDURE order_totals()
BEGIN
    DECLARE v_done_o INT DEFAULT FALSE;
    DECLARE v_o_id   INT;
    DECLARE v_cust   VARCHAR(50);

    DECLARE v_done_i INT DEFAULT FALSE;
    DECLARE v_p_id   INT;
    DECLARE v_qty    INT;
    DECLARE v_price  DECIMAL(10,2);
    DECLARE v_total  DECIMAL(12,2);

    DECLARE cur_orders CURSOR FOR SELECT id, customer FROM orders ORDER BY id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done_o = TRUE;

    OPEN cur_orders;
    o_loop: LOOP
        FETCH cur_orders INTO v_o_id, v_cust;
        IF v_done_o THEN LEAVE o_loop; END IF;

        SET v_total = 0;
        SET v_done_i = FALSE;

        BEGIN
            DECLARE cur_items CURSOR FOR
                SELECT product_id, qty FROM order_items WHERE order_id = v_o_id;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done_i = TRUE;

            OPEN cur_items;
            i_loop: LOOP
                FETCH cur_items INTO v_p_id, v_qty;
                IF v_done_i THEN LEAVE i_loop; END IF;

                SELECT price INTO v_price FROM products WHERE id = v_p_id;
                SET v_total = v_total + IFNULL(v_price,0) * v_qty;
            END LOOP i_loop;
            CLOSE cur_items;
        END;

        SELECT v_o_id AS order_id, v_cust AS customer, v_total AS total;
    END LOOP o_loop;
    CLOSE cur_orders;
END;
CALL order_totals();
