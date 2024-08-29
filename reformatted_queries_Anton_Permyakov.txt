/* Query 1: query used for first insight */
/* I wanted to write a query that lists the month and year, the total number of rental orders fulfilled by all stores in each month, and the average number of rental orders fulfilled per store in that month.*/

--  Calculating the total number of rental orders fulfilled by each store in each month
WITH rental_counts AS
  (SELECT DATE_TRUNC('month', r.rental_date) AS rental_month_year,
          st.store_id,
          COUNT(*) AS total_rental_orders
   FROM rental r
   JOIN inventory i ON r.inventory_id = i.inventory_id
   JOIN store st ON i.store_id = st.store_id
   GROUP BY rental_month_year,
            st.store_id),

-- Calculating the number of distinct stores for each month
     store_counts AS
  (SELECT DATE_TRUNC('month', r.rental_date) AS rental_month_year,
          st.store_id,
          COUNT(DISTINCT i.store_id) AS total_stores
   FROM rental r
   JOIN inventory i ON r.inventory_id = i.inventory_id
   JOIN store st ON i.store_id = st.store_id
   GROUP BY rental_month_year,
            st.store_id)

-- Combining the results from the two CTEs and calculating the average rental orders per store
SELECT rc.store_id,
       DATE(rc.rental_month_year) AS rental_month_year,
       rc.total_rental_orders,
       sc.total_stores,
       rc.total_rental_orders / sc.total_stores AS avg_rental_orders_per_store
FROM rental_counts rc
JOIN store_counts sc ON rc.rental_month_year = sc.rental_month_year
AND rc.store_id = sc.store_id
ORDER BY rc.store_id,
         rental_month_year;

/* Query 2: query used for second insight */
/* I wanted to find the top 5 countries with biggest payment amounts done by customers and I want to see their rental duration. */

-- Calculating the total payment amount for each country
WITH country_payments AS
  (SELECT co.country,
          SUM(p.amount) AS total_payment_amount
   FROM payment p
   JOIN customer c ON p.customer_id = c.customer_id
   JOIN address a ON c.address_id = a.address_id
   JOIN city ci ON a.city_id = ci.city_id
   JOIN country co ON ci.country_id = co.country_id
   GROUP BY co.country
   ORDER BY total_payment_amount DESC
   LIMIT 5),

-- Calculating the average rental duration for each country
     country_rental_duration AS
  (SELECT co.country,
          AVG(f.rental_duration) AS avg_rental_duration
   FROM film f
   JOIN film_category fc ON f.film_id = fc.film_id
   JOIN category c ON fc.category_id = c.category_id
   JOIN inventory i ON f.film_id = i.film_id
   JOIN rental r ON i.inventory_id = r.inventory_id
   JOIN customer cu ON r.customer_id = cu.customer_id
   JOIN address a ON cu.address_id = a.address_id
   JOIN city ci ON a.city_id = ci.city_id
   JOIN country co ON ci.country_id = co.country_id
   GROUP BY co.country)

-- Joining the total payment amount and average rental duration for each country
SELECT cp.country,
       cp.total_payment_amount,
       crd.avg_rental_duration
FROM country_payments cp
JOIN country_rental_duration crd ON cp.country = crd.country;



/* Query 3: query used for third insight */
/* I wanted to analyse the distribution of film lengths across different film categories by creating a query to retrieve the average film length for each film category and the average for all categories. */
/* Reference for UNION ALL : https://www.w3schools.com/sql/sql_union.asp */

-- Calculating the average film length for each category
WITH category_avg_length AS
  (SELECT c.name AS category,
          AVG(f.length) AS avg_film_length
   FROM film f
   JOIN film_category fc ON f.film_id = fc.film_id
   JOIN category c ON fc.category_id = c.category_id
   GROUP BY c.name),

-- Calculating the overall average film length
     overall_avg_length AS
  (SELECT AVG(LENGTH) AS overall_avg_film_length
   FROM film)

-- Combining the results of average film length for each category and overall average film length
SELECT category,
       avg_film_length
FROM category_avg_length
UNION ALL
SELECT 'Overall' AS category,
       overall_avg_film_length
FROM overall_avg_length;

/* Query 4: query used for forth insight */
-- Calculating the total monthly rental revenue for all stores combined
WITH monthly_revenue AS
  (SELECT DATE_TRUNC('month', r.rental_date) AS rental_month,
          SUM(p.amount) AS monthly_revenue
   FROM rental r
   JOIN payment p ON r.rental_id = p.rental_id
   GROUP BY DATE_TRUNC('month', r.rental_date)),

-- Calculating the cumulative rental revenue over time for all stores combined
     cumulative_revenue AS
  (SELECT rental_month,
          monthly_revenue,
          SUM(monthly_revenue) OVER (ORDER BY rental_month) AS cumulative_revenue
   FROM monthly_revenue)
SELECT rental_month,
       monthly_revenue,
       cumulative_revenue
FROM cumulative_revenue
ORDER BY rental_month;
