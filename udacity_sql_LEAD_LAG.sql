/* LAD, LEAD example on sum of standard quantities per account, ordered
   by increasing standard quantities*/
SELECT account_id,
       standard_sum,
       LAG(standard_sum) OVER (ORDER BY standard_sum) AS lag,
       LEAD(standard_sum) OVER (ORDER BY standard_sum) AS lead,
       standard_sum - LAG(standard_sum) OVER (ORDER BY standard_sum) AS lag_difference,
       LEAD(standard_sum) OVER (ORDER BY standard_sum) - standard_sum AS lead_difference
FROM (
    SELECT account_id,
           SUM(standard_qty) AS standard_sum
    FROM orders
    GROUP BY 1
) sub;

/* Alternative, prefer sorting the "original series" and then carrying out
   various LAG/LEAD opperations on it*/
SELECT account_id,
       standard_sum,
       LAG(standard_sum) OVER () AS lag,
       LEAD(standard_sum) OVER () AS lead,
       standard_sum - LAG(standard_sum) OVER () AS lag_difference,
       LEAD(standard_sum) OVER () - standard_sum AS lead_difference
FROM (
    SELECT account_id,
           SUM(standard_qty) AS standard_sum
    FROM orders
    GROUP BY 1
    ORDER BY 2
) sub;

/* Simple lag_difference computation on total order amounts between time
   consecutive orders*/
SELECT occurred_at,
       id,
       total_amt_usd,
       total_amt_usd - LAG(total_amt_usd) OVER (ORDER BY occurred_at)
       AS lag_difference
FROM orders
LIMIT 100;
