
/* Checking if each account has a designated sales rep and visa versa */

SELECT a.*, s.name, s.region_id
FROM accounts a
FULL JOIN sales_reps s
	ON a.sales_rep_id = s.id
WHERE s.name IS NULL OR a.name IS NULL;

/* Using JOINs with comparison to output the web events that occured before a
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

/* Using self JOINs to identify all web_events that have occured within
   1 day interval of another web_event */

SELECT w1.id AS o1_id,
       w1.account_id AS o1_account_id,
       w1.occurred_at AS o1_occurred_at,
       w1.channel AS o1_channel,
       w2.id AS o2_id,
       w2.account_id AS o2_account_id,
       w2.occurred_at AS o2_occurred_at,
       w2.channel AS o2_channel
  FROM web_events w1
 LEFT JOIN web_events w2
   ON w1.account_id = w2.account_id
  AND w2.occurred_at > w1.occurred_at
  AND w2.occurred_at <= w1.occurred_at + INTERVAL '1 days'
ORDER BY w1.account_id, w1.occurred_at
