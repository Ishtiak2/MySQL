-- Section 6. Stored Functions
-- Setup under § 6.1 — Creating a stored function
-- Source: MySQL-Stored-Procedures.md

CREATE FUNCTION function_name(
    [IN] p_param type [,...]
)
RETURNS return_type
    [DETERMINISTIC | NOT DETERMINISTIC]
    [SQL DATA | CONTAINS SQL | READS SQL DATA | MODIFIES SQL DATA]
    BEGIN
        -- declarations (DECLARE)
        -- statements
        RETURN expression;     -- must appear, value is sent back to caller
    END;