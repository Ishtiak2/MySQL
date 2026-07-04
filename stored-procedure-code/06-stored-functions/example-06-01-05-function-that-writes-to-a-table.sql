-- Section 6. Stored Functions
-- Example 6.1.5 — function that writes to a table
-- Source: MySQL-Stored-Procedures.md

DROP TABLE IF EXISTS call_log;
CREATE TABLE call_log (
    id        INT PRIMARY KEY AUTO_INCREMENT,
    fn_called VARCHAR(100),
    at_when   DATETIME DEFAULT CURRENT_TIMESTAMP
);


CREATE FUNCTION log_call(p_name VARCHAR(100))
RETURNS INT
    MODIFIES SQL DATA
BEGIN
    INSERT INTO call_log (fn_called) VALUES (p_name);
    RETURN LAST_INSERT_ID();
END;
SELECT log_call('first');
SELECT log_call('second');
SELECT * FROM call_log;
