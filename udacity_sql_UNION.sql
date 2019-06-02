/* Experiment with use of UNION ALL, in this case to join two identical accounts
   tables and then to count instance of each account*/

WITH double_accounts AS (
    SELECT *
    FROM accounts

    UNION ALL

    SELECT *
    FROM accounts)

SELECT name,
       COUNT(*) AS name_count
FROM double_accounts
GROUP BY 1
ORDER BY 2 DESC;
