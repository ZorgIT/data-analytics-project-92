/*
получение общего количество покупателей из таблици customers
*/
select count(*) as customers_count
from customers c;

/*
Получение данных по 10 продавцам у которых наибольшая выручка
*/

with tab as (
	select 
		s.sales_person_id,
		sum(s.quantity * p.price) as income
	from 
		sales s
	left join 
		employees e 
		on s.sales_person_id = e.employee_id
	left join 
		products p
		on s.product_id = p.product_id
	group by 
		s.sales_person_id
	order by 
		income desc
	limit 10),
tab2 as (
	SELECT 
	    s.sales_person_id,
	    COUNT(s.sales_id) AS total_sales_count
	FROM 
	    sales s
	GROUP BY 
	    s.sales_person_id
)
select concat(e.first_name,' ', e.last_name) as seller,
t2.total_sales_count as operations,
round(t.income) as income
from tab t
left join tab2 t2
	on t.sales_person_id = t2.sales_person_id
left join employees e 
	on 	t.sales_person_id = e.employee_id
order by t.income desc;
/*
получение продавцов чья выручка ниже средней выручки всех продавцов
*/
WITH avg_inc AS (
    SELECT 
        s.sales_person_id,
        AVG(ceil(s.quantity * p.price)) AS average_income
    FROM 
        sales s
    LEFT JOIN 
        employees e ON s.sales_person_id = e.employee_id
    LEFT JOIN 
        products p ON s.product_id = p.product_id
    GROUP BY 
        s.sales_person_id
),
avg_full AS (
    SELECT
        AVG(average_income) AS total_average
    FROM avg_inc
)
SELECT 
    e.first_name || ' ' || e.last_name AS seller,
    ROUND(ai.average_income) AS average_income
FROM 
    avg_inc AS ai
LEFT JOIN 
    employees e ON ai.sales_person_id = e.employee_id 
WHERE 
    ai.average_income < (SELECT total_average FROM avg_full)
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
            WHEN day_of_week_numeric = 1 THEN 'monday'
            WHEN day_of_week_numeric = 2 THEN 'tuesday'
            WHEN day_of_week_numeric = 3 THEN 'wednesday'
            WHEN day_of_week_numeric = 4 THEN 'thursday'
            WHEN day_of_week_numeric = 5 THEN 'friday'
            WHEN day_of_week_numeric = 6 THEN 'saturday'
            WHEN day_of_week_numeric = 7 THEN 'sunday'
        END AS day_of_week
    FROM 
        sales_with_day
)
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    d.day_of_week,
    ROUND(SUM(ins.income)) AS income
FROM 
    sales s
LEFT JOIN 
    sales_with_day_text d ON s.sales_id = d.sales_id
LEFT JOIN 
    employees e ON s.sales_person_id = e.employee_id
LEFT JOIN 
    income_sales ins ON s.sales_id = ins.sales_id
GROUP BY 
    d.day_of_week_numeric, seller,d.day_of_week
ORDER BY 
    day_of_week_numeric, seller;
	
/*
Получение количества продаж по каждой возростной группе
*/
WITH age_groups AS (
    SELECT 
        CASE 
            WHEN age >= 16 AND age <= 25 THEN '16-25'
            WHEN age >= 26 AND age <= 40 THEN '26-40'
            ELSE '40+' 
        END AS age_category
    FROM public.customers
),
age_counts AS (
    SELECT 
        age_category,
        COUNT(*) AS count
    FROM age_groups
    GROUP BY age_category
)

SELECT 
    age_category,
    count
FROM age_counts
ORDER BY 
    CASE 
        WHEN age_category = '16-25' THEN 1
        WHEN age_category = '26-40' THEN 2
        ELSE 3 
    END;
	
/*
Получение количества уникальных покупателей и выручке которую они принесли.
*/
WITH incomes AS (
    SELECT 
        s.sales_id,
        (s.quantity * p.price) AS income
    FROM sales s
    LEFT JOIN products p 
        ON s.product_id = p.product_id
), 
selling_month AS (
    SELECT 
        s.sales_id,
        EXTRACT(YEAR FROM s.sale_date) AS year,
        EXTRACT(MONTH FROM s.sale_date) AS month
    FROM sales AS s
)

SELECT 
    CONCAT(sm.year, '-', LPAD(sm.month::text, 2, '0')) AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(inc.income)) AS total_income
FROM sales s
LEFT JOIN selling_month AS sm
    ON s.sales_id = sm.sales_id
LEFT JOIN incomes inc
    ON s.sales_id = inc.sales_id
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
        MIN(s.sale_date) AS first_purchase_date  -- Самая ранняя дата покупки с нулевой стоимостью
    FROM 
        sales s
    JOIN 
        products p ON s.product_id = p.product_id
    WHERE 
        p.price = 0  -- Фильтруем акционные товары
    GROUP BY 
        s.customer_id
), 
tab2 AS (
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
    ORDER BY 
        c.customer_id
)
SELECT 
    customer,
    sale_date,
    seller
FROM 
    tab2
GROUP BY 
    customer, sale_date, seller;
	


	
	