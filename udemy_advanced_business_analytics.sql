-- Finding all data about costomer's first order
-- Should have 1 row for each customer

SELECT *
FROM (
	SELECT p.*
	FROM payment p
	JOIN (
		SELECT customer_id, MIN(payment_date) AS f_date
		FROM payment
		GROUP BY 1
	)t ON t.f_date = p.payment_date
	ORDER BY 2
)n WHERE n.staff_id = 2;


-- row number
-- get customer's 5 most recent orders?

SELECT t.* 
FROM (
	SELECT p.*,
		   ROW_NUMBER() OVER (PARTITION BY p.customer_id ORDER BY p.payment_date) AS order_num
	FROM payment p) t
WHERE t.order_num < 6
ORDER BY 2;

WITH first_orders AS (
					SELECT t.* 
					FROM (
						SELECT p.*,
							   ROW_NUMBER() OVER (PARTITION BY p.customer_id ORDER BY p.payment_date) AS order_num
						FROM payment p) t
					WHERE t.order_num = 1
					ORDER BY 2)
SELECT * FROM first_orders;

-- row number
-- can you get a list of orders by staff member, in reverse order?

SELECT t.* 
FROM (
	SELECT p.*,
		   ROW_NUMBER() OVER (PARTITION BY p.staff_id ORDER BY p.payment_date DESC) AS order_num
	FROM payment p
	ORDER BY 3) t 
WHERE t.order_num <6;

-- CTE random_numbers

WITH random_numbers AS (
		SELECT random()*100 val
		FROM generate_series(1,100))
SELECT rn.*,
	   CASE
	   	 WHEN rn.val < 50 THEN 'lt_50'
		 WHEN rn.val >=50 THEN 'mt_50'
	   END AS rand_outcome
FROM random_numbers rn;

-- Get order number

WITH order_numbers AS (SELECT p.*, row_number() OVER (PARTITION BY p.customer_id ORDER BY p.payment_date) order_nm
					   FROM payment p)
SELECT ons.*,
	   CASE
	   	 WHEN ons.order_nm = 1 THEN 'first_order'
		 WHEN ons.order_nm >1  THEN 'repeat_order'
	   END AS order_type
FROM order_numbers ons;

-- Get buyer_id, first order date, last order date and total spend (LTV)

WITH customer_orders AS
		(SELECT p.customer_id, p.payment_date,
			   row_number() OVER (PARTITION BY p.customer_id ORDER BY p.payment_date ASC)  AS first_order,
			   row_number() OVER (PARTITION BY p.customer_id ORDER BY p.payment_date DESC) AS last_order
		FROM payment p),
	 edge_orders AS
		(SELECT co.*
		FROM customer_orders co
		WHERE first_order = 1 OR last_order = 1)

SELECT customer_id, 
	   MIN(payment_date) AS first_order, 
	   MAX(payment_date) AS last_order,
	   (
		   SELECT SUM(p2.amount) FROM payment p2 WHERE p2.customer_id = eo.customer_id 
	   ) AS ltv_spend
FROM edge_orders eo
GROUP BY 1
ORDER BY 1

-- Get preferred movie rating of each customer
WITH customer_rating_count AS 
	(SELECT r.customer_id, f.rating, COUNT(r.*),
	 		row_number() OVER(PARTITION BY r.customer_id ORDER BY COUNT(r.*) DESC) AS rating_rank
	FROM rental r
		JOIN inventory i ON i.inventory_id = r.inventory_id
		JOIN film f 	 ON f.film_id = i.film_id
	GROUP BY 1,2
	ORDER BY 1,2)
SELECT * 
FROM customer_rating_count crc
WHERE crc.rating_rank = 1
ORDER BY 1

-- List all watched ratings for each customer
SELECT 	r.customer_id, 
		ARRAY_AGG (DISTINCT f.rating) AS movie_ratings_rented,
		COUNT (DISTINCT f.rating) AS count_of_movie_ratings_rented
FROM rental r
	JOIN inventory i ON i.inventory_id = r.inventory_id
	JOIN film f 	 ON f.film_id = i.film_id
GROUP BY 1
ORDER BY 1

