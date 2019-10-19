-- Finding all data about costomer's first order
-- Should have 1 row for each customer
-- Filter by customers served by staff member with staff_id=2

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

-- get customer's first orders
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
-- limit to last five orders by staff member 

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
-- Annotate first order and repeat orders per customer

WITH order_numbers AS (
	SELECT p.*, 
		   ROW_NUMBER() OVER (PARTITION BY p.customer_id ORDER BY p.payment_date) order_nm
		   FROM payment p)
SELECT ons.*,
	   CASE
	   	 WHEN ons.order_nm = 1 THEN 'first_order'
		 WHEN ons.order_nm >1  THEN 'repeat_order'
	   END AS order_type
FROM order_numbers ons;

-- Get customer_id, first order date, last order date and total spend (LTV)

WITH customer_orders AS
		(SELECT p.customer_id, p.payment_date,
			   ROW_NUMBER() OVER (PARTITION BY p.customer_id ORDER BY p.payment_date ASC)  AS first_order,
			   ROW_NUMBER() OVER (PARTITION BY p.customer_id ORDER BY p.payment_date DESC) AS last_order
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
ORDER BY 1;

-- Get preferred movie rating of each customer
WITH customer_rating_count AS 
	(SELECT r.customer_id, f.rating, COUNT(r.*),
	 		ROW_NUMBER() OVER(PARTITION BY r.customer_id ORDER BY COUNT(r.*) DESC) AS rating_rank
	FROM rental r
		JOIN inventory i ON i.inventory_id = r.inventory_id
		JOIN film f 	 ON f.film_id = i.film_id
	GROUP BY 1,2
	ORDER BY 1,2)
SELECT * 
FROM customer_rating_count crc
WHERE crc.rating_rank = 1
ORDER BY 1;

-- List all watched ratings for each customer
SELECT 	r.customer_id, 
		ARRAY_AGG (DISTINCT f.rating) AS movie_ratings_rented,
		COUNT (DISTINCT f.rating) AS count_of_movie_ratings_rented
FROM rental r
	JOIN inventory i ON i.inventory_id = r.inventory_id
	JOIN film f 	 ON f.film_id = i.film_id
GROUP BY 1
ORDER BY 1;

-- Show sales by staff for each day/hour and each staff member's sales as percentage of total sales in that day/hour
WITH sales_by_hour AS (
         SELECT payment.payment_date::date AS payment_date,
                date_part('hour'::text, payment.payment_date) AS hour,
                payment.staff_id,
            	SUM(payment.amount) AS hourly_sales
         FROM payment
         GROUP BY 1,2,3
         ORDER BY 1,2,3),
		 
		 staff_1_sales AS (
         SELECT sales_by_hour.payment_date,
                sales_by_hour.hour,
            	sales_by_hour.hourly_sales
         FROM sales_by_hour
         WHERE sales_by_hour.staff_id = 1), 
		 
		 staff_2_sales AS (
         SELECT sales_by_hour.payment_date,
            	sales_by_hour.hour,
            	sales_by_hour.hourly_sales
         FROM sales_by_hour
         WHERE sales_by_hour.staff_id = 2)
		 
SELECT s1.payment_date,
    s1.hour,
    (s1.payment_date::text ||' '|| s1.hour::text || ':00')::timestamp without time zone AS date_hour_ts,
    s1.hourly_sales AS s1_sales,
    s2.hourly_sales AS s2_sales,
    round(s1.hourly_sales / (s1.hourly_sales + s2.hourly_sales) * 100::numeric, 2) AS s1_perc_hourly_sales,
    round(s2.hourly_sales / (s1.hourly_sales + s2.hourly_sales) * 100::numeric, 2) AS s2_perc_hourly_sales
FROM staff_1_sales s1
JOIN staff_2_sales s2 
  ON s1.payment_date = s2.payment_date AND s1.hour = s2.hour
ORDER BY s1.payment_date, s1.hour;

-- Show time elapsed between each rental date of individual customer in hours, 
-- and average time interval between rentals by city and country (and add customer info city, country)
WITH interval_t AS
	(SELECT t.customer_id, t.rental_date, 
		   t.rental_date - t.prior_rental_date AS raw_interval,
		   round(EXTRACT(EPOCH FROM t.rental_date-t.prior_rental_date)::numeric / 3600,2) AS hours_interval
	FROM	   
		(SELECT customer_id, 
			   rental_date,
			   LAG(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date) AS prior_rental_date
		FROM rental
		ORDER BY customer_id, rental_date) t
	),
	avr_interval AS (
	SELECT intt.customer_id, AVG(intt.hours_interval) AS avg_hour_interval
	FROM interval_t intt
	GROUP BY intt.customer_id
	ORDER BY intt.customer_id
	)
SELECT c.id, c.city, c.country,
	   round(aint.avg_hour_interval,2) AS avg_hour_interval
FROM customer_list AS c
JOIN avr_interval AS aint
  ON aint.customer_id = c.id
ORDER BY c.country,aint.avg_hour_interval;  


-- to tableau - customer id, rental date, raw interval, interval in hours, rental rank (order by customer by date)
SELECT t.customer_id, t.rental_date, 
	   t.rental_date - t.prior_rental_date AS raw_interval,
	   round(EXTRACT(EPOCH FROM t.rental_date-t.prior_rental_date)::numeric / 3600,2) AS hours_interval,
	   t.rental_rank
FROM	   
	(SELECT customer_id, 
		   rental_date,
		   LAG(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date) AS prior_rental_date,
		   ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY rental_date) AS rental_rank
	FROM rental
	ORDER BY customer_id, rental_date) t;
	
-- show movies ordered by total sales of each, and corresponding decile

SELECT f.film_id, f.title, SUM(p.amount) AS total_sales,
	   NTILE(10) OVER(ORDER BY SUM(p.amount) DESC) AS sales_dist
FROM payment p
  JOIN rental r ON r.rental_id = p.rental_id
  JOIN inventory i ON r.inventory_id = i.inventory_id
  JOIN film f on f.film_id = i.film_id 
GROUP BY f.film_id, f.title
ORDER BY SUM(p.amount) DESC;

-- show sales amount brought in by each decile

WITH perc_dist AS 
	(SELECT f.film_id, f.title, SUM(p.amount) AS total_sales,
		   NTILE(10) OVER(ORDER BY SUM(p.amount) DESC) AS sales_dist
	FROM payment p
	  JOIN rental r ON r.rental_id = p.rental_id
	  JOIN inventory i ON r.inventory_id = i.inventory_id
	  JOIN film f on f.film_id = i.film_id 
	GROUP BY f.film_id, f.title
	ORDER BY SUM(p.amount) DESC)
SELECT sales_dist AS decile, SUM(total_sales) sales_by_decile
FROM perc_dist
GROUP BY 1
ORDER BY 1;

-- show movie ratings distribution of first rentals
WITH rental_ord AS
	(SELECT customer_id, rental_date, rental_id, inventory_id, 
		   ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY rental_date) AS rental_order
	FROM rental
	ORDER BY 1,2)
SELECT f.rating, COUNT(*) AS rating_count
FROM rental_ord ro 
JOIN inventory i ON i.inventory_id = ro.inventory_id
JOIN film f ON f.film_id = i.film_id
WHERE ro.rental_order = 1
GROUP BY CUBE (f.rating)
ORDER BY 2 DESC;

-- Does first time rented movie rating predict lifetime value?
WITH rental_ord AS (
	SELECT * FROM (
		SELECT customer_id, rental_date, rental_id, inventory_id, 
		   ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY rental_date) AS rental_order
		FROM rental
		ORDER BY 1,2) t 
	WHERE t.rental_order =1 
	),
	
	rating_first_order AS (
	SELECT ro.customer_id, ro.rental_id, ro.inventory_id, f.rating
	FROM rental_ord ro
	  JOIN inventory i ON i.inventory_id = ro.inventory_id
	  JOIN film f 	   ON f.film_id = i.film_id
	),
	
	customer_ltv AS (
	SELECT customer_id, SUM(amount) AS customer_total_spend
	FROM payment
	GROUP BY customer_id),
	
	rental_duration AS (
	SELECT t2.customer_id, MIN(t2.rental_date), MAX(t2.rental_date),
  		   EXTRACT(EPOCH FROM MAX(t2.rental_date) - MIN(t2.rental_date))::numeric/3600 AS customer_term_hrs
	FROM (
		 SELECT 	t1.* 
		 FROM
			(SELECT customer_id, rental_date,  
				   ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY rental_date) AS rental_order,
				   ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY rental_date DESC) AS rental_order_rev
			FROM rental
			ORDER BY 1,2) t1
		 WHERE t1.rental_order = 1 OR t1.rental_order_rev = 1) t2
	GROUP BY t2.customer_id
	)

SELECT t3.rating, t3.customer_term_grp, 
	   AVG(t3.f_annual_spend) AS average_annual_spend, 
	   MIN(t3.f_annual_spend) AS min_annual_spend, 
	   MAX(t3.f_annual_spend) AS max_annual_spend
FROM (
	SELECT fo.customer_id, fo.rating, 
	   cltv.customer_total_spend,
	   rd.customer_term_hrs,
	   cltv.customer_total_spend/rd.customer_term_hrs*(365*24)::numeric AS f_annual_spend,
	   CASE 
		 WHEN rd.customer_term_hrs <= 3000 THEN '125 days or less'
	     WHEN rd.customer_term_hrs > 3000 THEN 'more than 125 days'
	   END AS customer_term_grp
	FROM rating_first_order fo
	  JOIN customer_ltv cltv ON cltv.customer_id = fo.customer_id 
	  JOIN rental_duration rd ON rd.customer_id = fo.customer_id) t3
GROUP BY 1,2
ORDER BY 3 DESC, 2;
  
-- Find the top 5% highest grossing actors and
-- % of customers who rented from one of their films

WITH t1 AS
	(SELECT fa.actor_id, fa.film_id, a.first_name||' '||a.last_name AS actor_name,
		   i.inventory_id, r.rental_id, p.payment_id, p.customer_id, p.amount
	FROM film_actor fa
	  JOIN actor a ON fa.actor_id = a.actor_id
	  JOIN film f  ON fa.film_id = f.film_id
	  JOIN inventory i ON f.film_id = i.film_id
	  JOIN rental r ON r.inventory_id = i.inventory_id
	  JOIN payment p ON p.rental_id = r.rental_id
	), 
	
-- check that payment_id and actor_id are unique to each row -- result from below query should be none
-- SELECT payment_id, actor_id, COUNT(*) FROM t1 GROUP BY 1,2 HAVING COUNT(*) >2 

-- see all actors associated with each payment
-- SELECT payment_id, COUNT(*), ARRAY_AGG(actor_name) FROM t1 GROUP BY 1
	t2 AS
	(SELECT actor_id, actor_name, 
		   SUM(amount) actor_gross_income,
		   NTILE(100) OVER(ORDER BY SUM(amount)) AS percentile
	FROM t1 
	GROUP BY 1,2 
	ORDER BY 3 DESC),
	
	t3 AS
	(SELECT *,
		   CASE 
			 WHEN actor_name IN (SELECT actor_name FROM t2 WHERE percentile > 95) THEN 1
			 ELSE 0
		   END AS customer_rented_top_actor
	FROM t1),
	
	t4 AS
	(SELECT customer_id, SUM(customer_rented_top_actor) AS number_of_top_actors_customer_saw,
		   CASE 
			 WHEN SUM(customer_rented_top_actor) > 0 THEN 1
			 ELSE 0
		   END AS indicative_of_rented	 
	FROM t3
	GROUP BY 1
	ORDER BY 1)

SELECT SUM(indicative_of_rented) AS customers_rented_top_actor, 
	   COUNT(*) AS all_customers, 
	   SUM(indicative_of_rented)::numeric/COUNT(*)::numeric*100 AS percentage
FROM t4;

-- Get films by highest gross revenue per actor

WITH t1 AS
	(SELECT f.film_id, COUNT(fa.actor_id) actor_count
	FROM film f
	  JOIN film_actor fa ON fa.film_id = f.film_id
	GROUP BY 1),

	t2 AS
	(SELECT f.film_id, f.title,
		   SUM(p.amount) as movie_earning
	FROM film f
	  JOIN inventory i ON f.film_id = i.film_id
	  JOIN rental r on r.inventory_id = i.inventory_id
	  JOIN payment p on p.rental_id = r.rental_id
	GROUP BY 1,2
	ORDER BY 3 DESC)

SELECT COALESCE (t1.film_id, t2.film_id) as film_id, t2.title, t2.movie_earning, t1.actor_count,
	   t2.movie_earning::numeric/t1.actor_count AS earning_per_actor,
	   ROW_NUMBER() OVER (ORDER BY t2.movie_earning DESC) AS movie_earnings_rank,
	   ROW_NUMBER() OVER (ORDER BY t2.movie_earning::numeric/t1.actor_count DESC) AS movie_earnings_per_actor_rank
FROM t1
  FULL JOIN t2 ON t1.film_id = t2.film_id
WHERE t2.movie_earning > 0 AND t1.actor_count > 0 
ORDER BY t2.movie_earning::numeric/t1.actor_count DESC NULLS LAST;

-- first, first 7, first 14  days, etc

SELECT d,
	   d + INTERVAL '7 days' AS int_7_days,
	   d + INTERVAL '14 days'AS int_14_days 
FROM generate_series('2017-01-01', current_date, INTERVAL '1 day') d

-- select first orders

WITH first_orders AS (
	SELECT t1.* 
	FROM 
		(SELECT *,
			   ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date) AS payment_order	
		FROM payment) t1
	WHERE t1.payment_order = 1) 
	
SELECT fo.customer_id, fo.payment_date AS first_payment_date, (
	   SELECT SUM(p.amount)	
	   FROM payment p	
	   WHERE p.customer_id = fo.customer_id) AS total_spend,
	   (SELECT SUM(p.amount)	
	   FROM payment p	
	   WHERE p.customer_id = fo.customer_id
	   AND p.payment_date BETWEEN fo.payment_date AND fo.payment_date + INTERVAL '7 days') AS first_7d_spend,
	   (SELECT SUM(p.amount)	
	   FROM payment p	
	   WHERE p.customer_id = fo.customer_id
	   AND p.payment_date BETWEEN fo.payment_date AND fo.payment_date + INTERVAL '14 days') AS first_14d_spend

FROM first_orders fo

-- create table customer_source
-- CREATE TABLE IF NOT EXISTS customer_source (
-- 	customer_id integer REFERENCES customer(customer_id) ON DELETE RESTRICT,
-- 	traffic_source text,
-- 	PRIMARY KEY(customer_id));
-- populate data from 'customer_sources.csv' prapared in 
-- Jupyter Notebook 'http://localhost:8888/notebooks/DVDRental%20-%20Create%20additional%20random%20data.ipynb' 

SELECT c.customer_id, c.first_name, c.email, cs.traffic_source 
FROM customer c
JOIN customer_source cs
  ON c.customer_id = cs.customer_id
ORDER BY c.customer_id

-- create table source_spend_all
-- CREATE TABLE IF NOT EXISTS source_spend_all (
-- 	spend_source text,
-- 	spend integer,
-- 	visits integer);
	
-- INSERT INTO source_spend_all (spend_source, spend, visits)
-- VALUES ('google / cpc',1606,995),
-- 	('direct / none',0,755),
-- 	('google / organic',170,455),
-- 	('moviereviews / display',2886,1200),
-- 	('bing / cpc',133,45)

-- Show spend per channel, and attributable income, margin and customers gained

CREATE VIEW channel_totals AS
(WITH table_1 AS
	(SELECT c.customer_id, c.first_name, c.email, cs.traffic_source, 
		   (SELECT SUM(p.amount) FROM payment p WHERE p.customer_id = c.customer_id) AS total_spend
	FROM customer c
	JOIN customer_source cs
	  ON c.customer_id = cs.customer_id
	ORDER BY c.customer_id
	)

SELECT t1.traffic_source, ssa.spend AS channel_spend, 
	   SUM(t1.total_spend) income_per_channel, 
	   (SUM(t1.total_spend)/3)::numeric margin_per_channel,
	   COUNT(*) customer_per_channel
FROM channel_totals t1
JOIN source_spend_all ssa 
  ON ssa.spend_source = t1.traffic_source 
GROUP BY 1,2
ORDER BY 2 DESC;
)

-- calculate income and margin earned by dollar of spend (in channel), and acquisition cost per customer

SELECT ct.*,
	   ROUND(income_per_channel/NULLIF(channel_spend,0),2) AS income_per_dollar_spent,
	   ROUND(margin_per_channel/NULLIF(channel_spend,0),2) AS margin_per_dollar_spent,
	   ROUND(channel_spend::numeric/NULLIF(customer_per_channel,0),2) AS CAC
FROM channel_totals ct
