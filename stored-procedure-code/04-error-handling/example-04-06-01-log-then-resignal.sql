-- Section 4. Error Handling
-- Example 4.6.1 — log then resignal
-- Source: MySQL-Stored-Procedures.md

DROP TABLE IF EXISTS error_log;
CREATE TABLE error_log (
    id    INT PRIMARY KEY AUTO_INCREMENT,
    when_ DATETIME DEFAULT CURRENT_TIMESTAMP,
    who   VARCHAR(100),
    msg   VARCHAR(500)
);


CREATE PROCEDURE risky_insert(IN p_name VARCHAR(100))
BEGIN
    -- If anything goes wrong, log it AND let the caller see the original error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO error_log (who, msg)
        VALUES (CURRENT_USER(), 'Failed while inserting');
        RESIGNAL;   -- <-- raise the original error again
    END;

    INSERT INTO products (id, name, price) VALUES (NULL, p_name, NULL);
END;
CALL risky_insert('oops');   -- fails because price is NOT NULL; logged; resignaled
SELECT * FROM error_log;
