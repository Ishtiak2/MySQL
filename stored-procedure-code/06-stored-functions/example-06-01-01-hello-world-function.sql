-- Section 6. Stored Functions
-- Example 6.1.1 — hello-world function
-- Source: MySQL-Stored-Procedures.md

CREATE FUNCTION say_hello()
RETURNS VARCHAR(50)
    DETERMINISTIC
BEGIN
    RETURN 'Hello from MySQL function!';
END;
SELECT say_hello() AS greeting;
