/* Add quartile, quantile, percentile classifications*/
SELECT id, account_id, occurred_at, standard_qty,
       NTILE(4) OVER (ORDER BY standard_qty) AS quartile,
       NTILE(5) OVER (ORDER BY standard_qty) AS quantile,
       NTILE(100) OVER (ORDER BY standard_qty) AS percentile
FROM orders
ORDER BY standard_qty DESC;
