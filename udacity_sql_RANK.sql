/* Adding order count */
SELECT id, account_id, total,
	   ROW_NUMBER() OVER (ORDER BY id) row_num
FROM orders
LIMIT 50;

/* Adding order count for each account */
SELECT id, account_id, total,
	   ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY id) row_num
FROM orders
LIMIT 50;

/* Ranking orders for each account according to month of occurance */
SELECT id, account_id, total,
	   RANK() OVER (PARTITION BY account_id
                    ORDER BY DATE_TRUNC('month', occurred_at)) date_rank
FROM orders
LIMIT 50;

/* Ranking total  paper ordered by size (from highest to lowest) for each
   account */
SELECT id, account_id, total,
	   RANK() OVER (PARTITION BY account_id
                    ORDER BY total DESC) total_rank
FROM orders
LIMIT 50;

/* Ranking orders for each account according to month of occurance
   using DENSE_RANK() */
SELECT id, account_id, total,
	   DENSE_RANK() OVER (PARTITION BY account_id
                    ORDER BY DATE_TRUNC('month', occurred_at)) date_rank
FROM orders
LIMIT 50;
