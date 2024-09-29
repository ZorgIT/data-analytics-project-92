/*
Получение общего количества покупателей из таблицы customers
*/
SELECT COUNT(*) AS total_customers
FROM 
	customers;

/*
Получение данных по 10 продавцам, у которых наибольшая выручка
*/
WITH income_data AS (
	SELECT
		s.sales_person_id,
		SUM(s.quantity * p.price) AS total_income
	FROM
		sales s
	LEFT JOIN
		products p ON s.product_id = p.product_id
	GROUP BY
		s.sales_person_id
	ORDER BY
		total_income DESC
	LIMIT 10
),
sales_count AS (
	SELECT
		s.sales_person_id,
		COUNT(s.sales_id) AS total_sales_count
	FROM
		sales s
	GROUP BY
		s.sales_person_id
)
SELECT
	CONCAT(e.first_name, ' ', e.last_name) AS seller,
	COALESCE(sc.total_sales_count, 0) AS total_operations,
	FLOOR(id.total_income) AS total_income
FROM
	income_data id
LEFT JOIN
	sales_count sc ON id.sales_person_id = sc.sales_person_id
LEFT JOIN
	employees e ON id.sales_person_id = e.employee_id
ORDER BY
	total_income DESC;

/*
Получение продавцов, чья выручка ниже средней выручки всех продавцов
*/
WITH avg_income AS (
	SELECT
		s.sales_person_id,
		AVG(s.quantity * p.price) AS average_income
	FROM
		sales s
	LEFT JOIN
		products p ON s.product_id = p.product_id
	GROUP BY
		s.sales_person_id
),
total_avg_income AS (
	SELECT
		AVG(average_income) AS overall_average_income
	FROM
		avg_income
)
SELECT
	CONCAT(e.first_name, ' ', e.last_name) AS seller,
	FLOOR(ai.average_income) AS average_income
FROM
	avg_income ai
LEFT JOIN
	employees e ON ai.sales_person_id = e.employee_id 
WHERE
	ai.average_income < (SELECT overall_average_income FROM total_avg_income)
ORDER BY
	average_income ASC;

/*
Получение данных по выручке по каждому продавцу и дню недели
*/
WITH income_sales AS (
	SELECT
		s.sales_id,
		SUM(s.quantity * p.price) AS income
	FROM
		sales s
	LEFT JOIN
		products p ON s.product_id = p.product_id
	GROUP BY 
		s.sales_id
), 
sales_with_day AS (
	SELECT
		s.sales_id,
		EXTRACT(ISODOW FROM s.sale_date) AS day_of_week_numeric
	FROM
		sales s
), 
sales_with_day_text AS (
	SELECT
		sales_id,
		day_of_week_numeric,
		CASE
			WHEN day_of_week_numeric = 1 THEN 'monday   '
			WHEN day_of_week_numeric = 2 THEN 'tuesday  '
			WHEN day_of_week_numeric = 3 THEN 'wednesday'
			WHEN day_of_week_numeric = 4 THEN 'thursday '
			WHEN day_of_week_numeric = 5 THEN 'friday   '
			WHEN day_of_week_numeric = 6 THEN 'saturday '
			WHEN day_of_week_numeric = 7 THEN 'sunday   '
		END AS day_of_week
	FROM
		sales_with_day
)
SELECT 
	CONCAT(e.first_name, ' ', e.last_name) AS seller,
	d.day_of_week,
	FLOOR(SUM(ins.income)) AS income
FROM 
	sales s
LEFT JOIN
	sales_with_day_text d ON s.sales_id = d.sales_id
LEFT JOIN
	employees e ON s.sales_person_id = e.employee_id
LEFT JOIN
	income_sales ins ON s.sales_id = ins.sales_id
GROUP BY
	d.day_of_week_numeric, seller, d.day_of_week
ORDER BY
	day_of_week_numeric, seller;

/*
Получение количества продаж по каждой возрастной группе
*/
WITH age_groups AS (
	SELECT
		CASE
			WHEN age BETWEEN 16 AND 25 THEN '16-25'
			WHEN age BETWEEN 26 AND 40 THEN '26-40'
			ELSE '40+'
		END AS age_category
	FROM
		customers
)
SELECT
	age_category,
	COUNT(*) AS total_count
FROM
	age_groups
GROUP BY
	age_category
ORDER BY
	CASE
		WHEN age_category = '16-25' THEN 1
		WHEN age_category = '26-40' THEN 2
		ELSE 3
	END;

/*
Получение количества уникальных покупателей и выручки, которую они принесли
*/
WITH incomes AS (
	SELECT
		s.customer_id,
		SUM(s.quantity * p.price) AS total_income
	FROM
		sales s
	LEFT JOIN
		products p ON s.product_id = p.product_id
	GROUP BY
		s.customer_id
),
selling_month AS (
	SELECT
		s.sales_id,
		EXTRACT(YEAR FROM s.sale_date) AS year,
		EXTRACT(MONTH FROM s.sale_date) AS month
	FROM
		sales AS s
)
SELECT 
	CONCAT(sm.year, '-', LPAD(sm.month::text, 2, '0')) AS selling_month,
	COUNT(DISTINCT s.customer_id) AS unique_customers,
	FLOOR(SUM(inc.total_income)) AS total_income
FROM
	sales s
LEFT JOIN
	selling_month AS sm ON s.sales_id = sm.sales_id
LEFT JOIN
	incomes inc ON s.customer_id = inc.customer_id
GROUP BY
	sm.year, sm.month
ORDER BY
	sm.year, sm.month;

/*
Получение информации о покупателях, первая покупка которых была в ходе проведения акций
*/
WITH first_purchase AS (
	SELECT
		s.customer_id,
		MIN(s.sale_date) AS first_purchase_date
	FROM
		sales s
	JOIN
		products p ON s.product_id = p.product_id
	WHERE
		p.price = 0
	GROUP BY
		s.customer_id
), 
purchase_info AS (
	SELECT
		CONCAT(c.first_name, ' ', c.last_name) AS customer,
		fp.first_purchase_date AS sale_date,
		CONCAT(e.first_name, ' ', e.last_name) AS seller
	FROM
		first_purchase fp
	JOIN
		sales s ON fp.customer_id = s.customer_id AND fp.first_purchase_date = s.sale_date
	LEFT JOIN
		customers c ON s.customer_id = c.customer_id
	LEFT JOIN
		employees e ON s.sales_person_id = e.employee_id
	LEFT JOIN
		products p ON s.product_id = p.product_id
	WHERE
		p.price = 0
)
SELECT
	customer,
	sale_date,
	seller
FROM
	purchase_info
ORDER BY
	customer, sale_date;
