CREATE OR REPLACE PROCEDURE populateCalendar()
LANGUAGE plpgsql
AS $$
DECLARE
    i INTEGER := 0;
BEGIN
    LOOP
        INSERT INTO staging.Calendar_Dimension (FullDate)
        VALUES ('2013-01-01'::date + i);
        
        i := i + 1;
        IF i = 10000 THEN
            EXIT;
        END IF;
    END LOOP;
    
    UPDATE staging.Calendar_Dimension
    SET MonthYear = EXTRACT(MONTH FROM FullDate),
        Year = EXTRACT(YEAR FROM FullDate);
END;
$$;
