
-- 1. What are the purchasing patterns of new customers versus repeat customers?

WITH customer_purchase AS (
    SELECT
        c.customer_id,
        COUNT(r.rental_id) AS total_rentals,
        SUM(p.amount) AS total_spent
    FROM customer c
    LEFT JOIN rental r
        ON c.customer_id = r.customer_id
    LEFT JOIN payment p
        ON r.rental_id = p.rental_id
    GROUP BY c.customer_id
),

customer_segment AS (
    SELECT *,
        CASE
            WHEN total_rentals = 1 THEN 'New Customer'
            ELSE 'Repeat Customer'
        END AS customer_type
    FROM customer_purchase
)

SELECT
    customer_type,
    COUNT(customer_id) AS customer_count,
    AVG(total_rentals) AS avg_rentals,
    AVG(total_spent) AS avg_spending,
    MAX(total_spent) AS max_spending
FROM customer_segment
GROUP BY customer_type;



-- 2. Which films have the highest rental rates and are most in demand?

SELECT
    f.film_id,
    f.title,
    f.rental_rate,
    COUNT(r.rental_id) AS total_rentals,

    CASE
        WHEN COUNT(r.rental_id) >= 30 THEN 'High Demand'
        WHEN COUNT(r.rental_id) >= 15 THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS demand_category

FROM film f
LEFT JOIN inventory i
    ON f.film_id = i.film_id
LEFT JOIN rental r
    ON i.inventory_id = r.inventory_id

GROUP BY
    f.film_id,
    f.title,
    f.rental_rate

ORDER BY
    f.rental_rate DESC,
    total_rentals DESC;



-- 3. Are there correlations between staff performance and customer satisfaction?	

WITH staff_metrics AS (
    SELECT
        s.staff_id,
        s.first_name || ' ' || s.last_name AS staff_name,

        COUNT(DISTINCT r.rental_id) AS total_rentals,

        COUNT(DISTINCT c.customer_id) AS total_customers,

        SUM(p.amount) AS total_revenue,

        ROUND(
            COUNT(r.rental_id)::NUMERIC /
            NULLIF(COUNT(DISTINCT c.customer_id),0),
            2
        ) AS avg_rentals_per_customer

    FROM staff s
    LEFT JOIN rental r
        ON s.staff_id = r.staff_id
    LEFT JOIN customer c
        ON r.customer_id = c.customer_id
    LEFT JOIN payment p
        ON r.rental_id = p.rental_id

    GROUP BY
        s.staff_id,
        staff_name
)

SELECT *,
    CASE
        WHEN avg_rentals_per_customer >= 2
            THEN 'High Satisfaction'
        WHEN avg_rentals_per_customer >= 1
            THEN 'Moderate Satisfaction'
        ELSE 'Low Satisfaction'
    END AS satisfaction_level

FROM staff_metrics
ORDER BY
    total_revenue DESC,
    avg_rentals_per_customer DESC;



-- 4. Are there seasonal trends in customer behavior across different locations?

SELECT
    co.country,
    ci.city,

    EXTRACT(YEAR FROM r.rental_date) AS year,
    EXTRACT(MONTH FROM r.rental_date) AS month,

    COUNT(r.rental_id) AS total_rentals,

    COUNT(DISTINCT r.customer_id) AS active_customers,

    SUM(p.amount) AS total_revenue,

    ROUND(
        SUM(p.amount) /
        COUNT(DISTINCT r.customer_id),
        2
    ) AS revenue_per_customer

FROM rental r

JOIN customer c
    ON r.customer_id = c.customer_id

JOIN address a
    ON c.address_id = a.address_id

JOIN city ci
    ON a.city_id = ci.city_id

JOIN country co
    ON ci.country_id = co.country_id

LEFT JOIN payment p
    ON r.rental_id = p.rental_id

GROUP BY
    co.country,
    ci.city,
    year,
    month

ORDER BY
    year,
    month,
    total_rentals DESC;


-- 5. Are certain language films more popular among specific customer segments?

WITH customer_segment AS (
    SELECT
        customer_id,
        CASE
            WHEN COUNT(rental_id) = 1
                THEN 'New Customer'
            ELSE 'Repeat Customer'
        END AS customer_type
    FROM rental
    GROUP BY customer_id
)

SELECT
    cs.customer_type,
    l.name AS film_language,

    COUNT(r.rental_id) AS total_rentals,

    COUNT(DISTINCT r.customer_id) AS unique_customers,

    SUM(p.amount) AS total_revenue,

    ROUND(
        AVG(p.amount),
        2
    ) AS avg_spending

FROM rental r

JOIN customer_segment cs
    ON r.customer_id = cs.customer_id

JOIN inventory i
    ON r.inventory_id = i.inventory_id

JOIN film f
    ON i.film_id = f.film_id

JOIN language l
    ON f.language_id = l.language_id

LEFT JOIN payment p
    ON r.rental_id = p.rental_id

GROUP BY
    cs.customer_type,
    l.name

ORDER BY
    total_rentals DESC,
    total_revenue DESC;


-- 6. How does customer loyalty impact sales revenue over time?

WITH customer_loyalty AS (
    SELECT
        customer_id,
        COUNT(rental_id) AS rental_count,

        CASE
            WHEN COUNT(rental_id) = 1
                THEN 'New Customer'
            WHEN COUNT(rental_id) BETWEEN 2 AND 5
                THEN 'Repeat Customer'
            ELSE 'Loyal Customer'
        END AS loyalty_segment
    FROM rental
    GROUP BY customer_id
)

SELECT
    EXTRACT(YEAR FROM r.rental_date) AS year,
    EXTRACT(MONTH FROM r.rental_date) AS month,

    cl.loyalty_segment,

    COUNT(DISTINCT r.customer_id) AS customers,

    COUNT(r.rental_id) AS total_rentals,

    SUM(p.amount) AS total_revenue,

    ROUND(
        SUM(p.amount) /
        COUNT(DISTINCT r.customer_id),
        2
    ) AS revenue_per_customer

FROM rental r

JOIN customer_loyalty cl
    ON r.customer_id = cl.customer_id

LEFT JOIN payment p
    ON r.rental_id = p.rental_id

GROUP BY
    year,
    month,
    cl.loyalty_segment

ORDER BY
    year,
    month,
    total_revenue DESC;


-- 7. Are certain film categories more popular in specific locations?


SELECT
    co.country,
    ci.city,

    cat.name AS film_category,

    COUNT(r.rental_id) AS total_rentals,

    COUNT(DISTINCT r.customer_id) AS unique_customers,

    SUM(p.amount) AS total_revenue,

    ROUND(
        AVG(p.amount),
        2
    ) AS avg_spending

FROM rental r

JOIN customer c
    ON r.customer_id = c.customer_id

JOIN address a
    ON c.address_id = a.address_id

JOIN city ci
    ON a.city_id = ci.city_id

JOIN country co
    ON ci.country_id = co.country_id

JOIN inventory i
    ON r.inventory_id = i.inventory_id

JOIN film_category fc
    ON i.film_id = fc.film_id

JOIN category cat
    ON fc.category_id = cat.category_id

LEFT JOIN payment p
    ON r.rental_id = p.rental_id

GROUP BY
    co.country,
    ci.city,
    cat.name

ORDER BY
    total_rentals DESC,
    total_revenue DESC;


-- 8. How does the availability and knowledge of staff affect customer ratings?


WITH customer_activity AS (
    SELECT
        customer_id,
        COUNT(rental_id) AS rental_frequency
    FROM rental
    GROUP BY customer_id
)

SELECT
    s.staff_id,

    s.first_name || ' ' || s.last_name AS staff_name,

    COUNT(DISTINCT r.rental_id) AS total_rentals_handled,

    COUNT(DISTINCT r.customer_id) AS total_customers,

    SUM(p.amount) AS total_revenue,

    ROUND(
        AVG(ca.rental_frequency),
        2
    ) AS avg_customer_repeat_rate,

    ROUND(
        SUM(p.amount) /
        NULLIF(COUNT(DISTINCT r.customer_id),0),
        2
    ) AS revenue_per_customer,

    CASE
        WHEN AVG(ca.rental_frequency) >= 3
            THEN 'High Satisfaction'
        WHEN AVG(ca.rental_frequency) >= 2
            THEN 'Moderate Satisfaction'
        ELSE 'Low Satisfaction'
    END AS estimated_customer_rating

FROM staff s

LEFT JOIN rental r
    ON s.staff_id = r.staff_id

LEFT JOIN payment p
    ON r.rental_id = p.rental_id

LEFT JOIN customer_activity ca
    ON r.customer_id = ca.customer_id

GROUP BY
    s.staff_id,
    staff_name

ORDER BY
    total_revenue DESC,
    avg_customer_repeat_rate DESC;


-- 9. How does the proximity of stores to customers impact rental frequency?


SELECT
    CASE
        WHEN cust_city.city = store_city.city
            THEN 'Near Store'

        WHEN cust_country.country =
             store_country.country
            THEN 'Same Country'

        ELSE 'Different Country'
    END AS proximity_group,

    COUNT(r.rental_id) AS total_rentals,

    COUNT(DISTINCT c.customer_id) AS total_customers,

    ROUND(
        COUNT(r.rental_id)::NUMERIC /
        COUNT(DISTINCT c.customer_id),
        2
    ) AS avg_rentals_per_customer

FROM customer c

JOIN address cust_addr
    ON c.address_id = cust_addr.address_id

JOIN city cust_city
    ON cust_addr.city_id = cust_city.city_id

JOIN country cust_country
    ON cust_city.country_id = cust_country.country_id

JOIN store st
    ON c.store_id = st.store_id

JOIN address store_addr
    ON st.address_id = store_addr.address_id

JOIN city store_city
    ON store_addr.city_id = store_city.city_id

JOIN country store_country
    ON store_city.country_id = store_country.country_id

LEFT JOIN rental r
    ON c.customer_id = r.customer_id

GROUP BY
    proximity_group

ORDER BY
    avg_rentals_per_customer DESC;



-- 10. Do specific film categories attract different age groups of customers?


WITH customer_segment AS (
    SELECT
        customer_id,
        COUNT(rental_id) AS rental_count,

        CASE
            WHEN COUNT(rental_id) = 1
                THEN 'New Customer'

            WHEN COUNT(rental_id) BETWEEN 2 AND 5
                THEN 'Regular Customer'

            ELSE 'Loyal Customer'
        END AS customer_group

    FROM rental
    GROUP BY customer_id
)

SELECT
    cs.customer_group,

    cat.name AS film_category,

    COUNT(r.rental_id) AS total_rentals,

    COUNT(DISTINCT r.customer_id) AS total_customers,

    SUM(p.amount) AS total_revenue

FROM rental r

JOIN customer_segment cs
    ON r.customer_id = cs.customer_id

JOIN inventory i
    ON r.inventory_id = i.inventory_id

JOIN film_category fc
    ON i.film_id = fc.film_id

JOIN category cat
    ON fc.category_id = cat.category_id

LEFT JOIN payment p
    ON r.rental_id = p.rental_id

GROUP BY
    cs.customer_group,
    cat.name

ORDER BY
    cs.customer_group,
    total_rentals DESC;


-- 11. What are the demographics and preferences of the highest-spending customers?



WITH customer_spending AS (
    SELECT
        c.customer_id,

        c.first_name || ' ' || c.last_name AS customer_name,

        ci.city,
        co.country,

        SUM(p.amount) AS total_spent,

        DENSE_RANK() OVER (
            ORDER BY SUM(p.amount) DESC
        ) AS spending_rank

    FROM customer c

    JOIN address a
        ON c.address_id = a.address_id

    JOIN city ci
        ON a.city_id = ci.city_id

    JOIN country co
        ON ci.country_id = co.country_id

    JOIN payment p
        ON c.customer_id = p.customer_id

    GROUP BY
        c.customer_id,
        customer_name,
        ci.city,
        co.country
),

customer_preferences AS (
    SELECT
        r.customer_id,

        cat.name AS favorite_category,

        COUNT(*) AS rentals,

        ROW_NUMBER() OVER (
            PARTITION BY r.customer_id
            ORDER BY COUNT(*) DESC
        ) AS rn

    FROM rental r

    JOIN inventory i
        ON r.inventory_id = i.inventory_id

    JOIN film_category fc
        ON i.film_id = fc.film_id

    JOIN category cat
        ON fc.category_id = cat.category_id

    GROUP BY
        r.customer_id,
        cat.name
)

SELECT
    cs.customer_id,
    cs.customer_name,
    cs.city,
    cs.country,
    cs.total_spent,
    cp.favorite_category

FROM customer_spending cs

LEFT JOIN customer_preferences cp
    ON cs.customer_id = cp.customer_id
    AND cp.rn = 1

WHERE spending_rank <= 10

ORDER BY
    total_spent DESC;



-- 12. How does the availability of inventory impact customer satisfaction and repeat business?



WITH inventory_availability AS (
    SELECT
        film_id,
        COUNT(inventory_id) AS available_copies
    FROM inventory
    GROUP BY film_id
),

customer_repeat AS (
    SELECT
        customer_id,
        COUNT(rental_id) AS rental_frequency
    FROM rental
    GROUP BY customer_id
)

SELECT
    f.title,

    ia.available_copies,

    COUNT(r.rental_id) AS total_rentals,

    COUNT(DISTINCT r.customer_id) AS total_customers,

    ROUND(
        AVG(cr.rental_frequency),
        2
    ) AS avg_repeat_rate,

    SUM(p.amount) AS total_revenue,

    CASE
        WHEN AVG(cr.rental_frequency) >= 5
            THEN 'High Satisfaction'

        WHEN AVG(cr.rental_frequency) >= 3
            THEN 'Moderate Satisfaction'

        ELSE 'Low Satisfaction'
    END AS satisfaction_level

FROM film f

JOIN inventory_availability ia
    ON f.film_id = ia.film_id

LEFT JOIN inventory i
    ON f.film_id = i.film_id

LEFT JOIN rental r
    ON i.inventory_id = r.inventory_id

LEFT JOIN customer_repeat cr
    ON r.customer_id = cr.customer_id

LEFT JOIN payment p
    ON r.rental_id = p.rental_id

GROUP BY
    f.title,
    ia.available_copies

ORDER BY
    avg_repeat_rate DESC,
    total_revenue DESC;



-- 13. What are the busiest hours or days for each store location, and how does it impact staffing requirements?


SELECT
    st.store_id,

    ci.city AS store_city,

    TO_CHAR(r.rental_date, 'Day') AS rental_day,

    EXTRACT(HOUR FROM r.rental_date) AS rental_hour,

    COUNT(r.rental_id) AS total_rentals,

    COUNT(DISTINCT r.staff_id) AS active_staff,

    ROUND(
        COUNT(r.rental_id)::NUMERIC /
        NULLIF(COUNT(DISTINCT r.staff_id), 0),
        2
    ) AS rentals_per_staff,

    CASE
        WHEN COUNT(r.rental_id)::NUMERIC /
             NULLIF(COUNT(DISTINCT r.staff_id), 0) > 20
            THEN 'High Staffing Need'

        WHEN COUNT(r.rental_id)::NUMERIC /
             NULLIF(COUNT(DISTINCT r.staff_id), 0) > 10
            THEN 'Moderate Staffing Need'

        ELSE 'Low Staffing Need'
    END AS staffing_requirement

FROM rental r

JOIN staff sf
    ON r.staff_id = sf.staff_id

JOIN store st
    ON sf.store_id = st.store_id

JOIN address a
    ON st.address_id = a.address_id

JOIN city ci
    ON a.city_id = ci.city_id

GROUP BY
    st.store_id,
    ci.city,
    rental_day,
    rental_hour

ORDER BY
    st.store_id,
    total_rentals DESC,
    rental_hour;



-- 14. What are the cultural or demographic factors that influence customer preferences in different locations?

WITH language_inventory AS (
    SELECT
        f.language_id,
        l.name AS language_name,
        COUNT(i.inventory_id) AS available_copies
    FROM film f
    JOIN language l
        ON f.language_id = l.language_id
    LEFT JOIN inventory i
        ON f.film_id = i.film_id
    GROUP BY
        f.language_id,
        l.name
),

customer_repeat AS (
    SELECT
        customer_id,
        COUNT(rental_id) AS rental_frequency
    FROM rental
    GROUP BY customer_id
)

SELECT
    li.language_name,

    li.available_copies,

    COUNT(r.rental_id) AS total_rentals,

    COUNT(DISTINCT r.customer_id) AS total_customers,

    ROUND(
        AVG(cr.rental_frequency),
        2
    ) AS avg_repeat_rate,

    SUM(p.amount) AS total_revenue,

    CASE
        WHEN AVG(cr.rental_frequency) >= 5
            THEN 'High Satisfaction'

        WHEN AVG(cr.rental_frequency) >= 3
            THEN 'Moderate Satisfaction'

        ELSE 'Low Satisfaction'
    END AS satisfaction_level

FROM language_inventory li

JOIN film f
    ON li.language_id = f.language_id

LEFT JOIN inventory i
    ON f.film_id = i.film_id

LEFT JOIN rental r
    ON i.inventory_id = r.inventory_id

LEFT JOIN customer_repeat cr
    ON r.customer_id = cr.customer_id

LEFT JOIN payment p
    ON r.rental_id = p.rental_id

GROUP BY
    li.language_name,
    li.available_copies

ORDER BY
    total_rentals DESC,
    avg_repeat_rate DESC;




-- 15. How does the availability of films in different languages impact customer satisfaction and rental frequency?

WITH language_inventory AS (
    SELECT
        f.language_id,
        l.name AS language_name,
        COUNT(i.inventory_id) AS available_copies
    FROM film f
    JOIN language l
        ON f.language_id = l.language_id
    LEFT JOIN inventory i
        ON f.film_id = i.film_id
    GROUP BY
        f.language_id,
        l.name
),

customer_repeat AS (
    SELECT
        customer_id,
        COUNT(rental_id) AS rental_frequency
    FROM rental
    GROUP BY customer_id
)

SELECT
    li.language_name,

    li.available_copies,

    COUNT(r.rental_id) AS total_rentals,

    COUNT(DISTINCT r.customer_id) AS total_customers,

    ROUND(
        AVG(cr.rental_frequency),
        2
    ) AS avg_repeat_rate,

    SUM(p.amount) AS total_revenue,

    CASE
        WHEN AVG(cr.rental_frequency) >= 5
            THEN 'High Satisfaction'

        WHEN AVG(cr.rental_frequency) >= 3
            THEN 'Moderate Satisfaction'

        ELSE 'Low Satisfaction'
    END AS satisfaction_level

FROM language_inventory li

JOIN film f
    ON li.language_id = f.language_id

LEFT JOIN inventory i
    ON f.film_id = i.film_id

LEFT JOIN rental r
    ON i.inventory_id = r.inventory_id

LEFT JOIN customer_repeat cr
    ON r.customer_id = cr.customer_id

LEFT JOIN payment p
    ON r.rental_id = p.rental_id

GROUP BY
    li.language_name,
    li.available_copies

ORDER BY
    total_rentals DESC,
    avg_repeat_rate DESC;
	