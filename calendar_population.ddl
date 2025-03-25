-- CHANGE DELIMITER TO $$ -- CALL populateCalendar() Afterwards
CREATE PROCEDURE populateCalendar()
BEGIN
    DECLARE i INT DEFAULT 0;
myloop:
LOOP
INSERT INTO Calendar_Dimension(FullDate)
SELECT DATE_ADD('2013-01-01', INTERVAL i DAY);
SET i=i+1;
IF i=10000 then
LEAVE myloop;
END
IF;
END LOOP myloop;
UPDATE Calendar_Dimension
SET MonthYear = MONTH(FullDate), Year = YEAR(FullDate);
END;