-- Section 3. Loops
-- Setup under § 3.5 — ITERATE statement (bonus — "continue")
-- Source: MySQL-Stored-Procedures.md

CREATE PROCEDURE print_odds(IN p_max INT)
BEGIN
    DECLARE v_i INT DEFAULT 0;

    odds: WHILE v_i < p_max DO
        SET v_i = v_i + 1;
        IF v_i % 2 = 0 THEN
            ITERATE odds;           -- skip even numbers
        END IF;
        SELECT v_i AS odd_number;
    END WHILE odds;
END;
CALL print_odds(7);   -- returns 1, 3, 5, 7
