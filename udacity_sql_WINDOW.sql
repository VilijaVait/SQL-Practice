/* Cummulative sum of standard amount, reset each year*/
SELECT occurred_at, standard_amt_usd,
	   SUM(standard_amt_usd) OVER (ORDER BY occurred_at) AS running_total
FROM orders
LIMIT 20;


SELECT DATE_TRUNC('year', occurred_at) AS year,
       standard_amt_usd,
	   SUM(standard_amt_usd) OVER (PARTITION BY DATE_TRUNC('year', occurred_at)
                                   ORDER BY occurred_at) AS running_total
FROM orders
LIMIT 20;


/* Order statistics by account, by month*/
SELECT id,
       account_id,
       standard_qty,
       DATE_TRUNC('month', occurred_at) AS month,
       DENSE_RANK() OVER main_window AS dense_rank,
       SUM(standard_qty) OVER main_window AS sum_std_qty,
       COUNT(standard_qty) OVER main_window AS count_std_qty,
       AVG(standard_qty) OVER main_window AS avg_std_qty,
       MIN(standard_qty) OVER main_window AS min_std_qty,
       MAX(standard_qty) OVER main_window AS max_std_qty
FROM orders
WINDOW main_window AS (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at))
LIMIT 100;
