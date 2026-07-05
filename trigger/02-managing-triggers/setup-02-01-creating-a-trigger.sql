-- Section 2. Managing MySQL Triggers
-- Setup under § 2.1 — Creating a trigger
-- Source: MySQL-Triggers.md

CREATE TRIGGER trigger_name
    {BEFORE | AFTER} {INSERT | UPDATE | DELETE}
    ON table_name
    FOR EACH ROW
BEGIN
    -- one or more SQL statements
END;
