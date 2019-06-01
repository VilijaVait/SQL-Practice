/* Illustraion of WITH usage, as well as a JOIN along two parameters/conditions,
   in this case outputting the name of highest grossing sales rep, sales
   attributable to that sales rep for each region*/

WITH rep_sales AS
    (SELECT s.name rep_name, r.name reg_name,
            SUM(o.total_amt_usd) amt_rep
    FROM orders o
    JOIN accounts a
        ON o.account_id = a.id
    JOIN sales_reps s
        ON a.sales_rep_id = s.id
    JOIN region r
        ON s.region_id = r.id
    GROUP BY 1,2)

SELECT rep_sales.rep_name, rep_sales.reg_name, tb1.max_reg
FROM(
    SELECT reg_name, MAX(amt_rep) max_reg
    FROM rep_sales
    GROUP BY reg_name) tb1

JOIN rep_sales
    ON tb1.reg_name = rep_sales.reg_name
 	AND tb1.max_reg = rep_sales.amt_rep;
