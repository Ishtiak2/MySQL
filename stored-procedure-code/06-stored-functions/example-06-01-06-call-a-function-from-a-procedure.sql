-- Section 6. Stored Functions
-- Example 6.1.6 — call a function from a procedure
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE enrich()
BEGIN
    SELECT id,
           name,
           price,
           get_product_name(id)                                AS same_name,
           price_with_tax(price, 0.07)                         AS with_tax,
           stock_label(stock)                                  AS stock_status,
           log_call(CONCAT('enrich:', name))                  AS log_id
    FROM products;
END;
CALL enrich();
