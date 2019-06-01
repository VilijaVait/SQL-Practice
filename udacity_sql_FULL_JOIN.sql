/* Checking if each account has a designated sales rep and visa versa */

SELECT a.*, s.name, s.region_id
FROM accounts a
FULL JOIN sales_reps s
	ON a.sales_rep_id = s.id
WHERE s.name IS NULL OR a.name IS NULL;

/*Using JOINs with comparison to output the web events that occured before a
specified date (the first day of orders)*/
SELECT orders.id AS order_id,
       orders.occurred_at AS order_date,
       events.occurred_at AS event_date,
       events.channel
FROM orders
LEFT JOIN web_events events
    ON events.account_id = orders.account_id
    AND events.occurred_at < orders.occurred_at
WHERE DATE_TRUNC('month', orders.occurred_at) =
      (SELECT DATE_TRUNC('month', MIN(orders.occurred_at)) FROM orders)
ORDER BY orders.account_id, orders.occurred_at;
