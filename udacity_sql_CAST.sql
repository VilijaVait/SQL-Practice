/* Using CAST to turn date into a recognisable format, and also practicing
   LEFT, SUBSTR, POSITION and CONCAT or ||*/
   
WITH tb1 AS
		(SELECT incidnt_num, date,
	  			 LEFT(date,2) AS month,
      			 SUBSTR(date, POSITION('/' IN date)+1,2) AS day,
     			 SUBSTR(date, POSITION(SUBSTR(date,
                        POSITION('/' IN date)+3,2) IN date)+1,4) AS year
		FROM sf_crime_data)

SELECT (year || month || day)::DATE
FROM tb1
LIMIT 10;

/* Alternative solution */

SELECT date orig_date, (SUBSTR(date, 7, 4) || '-' || LEFT(date, 2) || '-' ||
                        SUBSTR(date, 4, 2))::DATE new_date
FROM sf_crime_data
LIMIT 10;
