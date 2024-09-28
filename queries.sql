/*
получение общего количество покупателей из таблици customers
*/
select count(*) as customer_count
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
select concat(e.first_name,' ', e.last_name),
t2.total_sales_count as operations,
t.income
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
        AVG(s.quantity * p.price) AS average_income
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
            WHEN day_of_week_numeric = 1 THEN 'Monday'
            WHEN day_of_week_numeric = 2 THEN 'Tuesday'
            WHEN day_of_week_numeric = 3 THEN 'Wednesday'
            WHEN day_of_week_numeric = 4 THEN 'Thursday'
            WHEN day_of_week_numeric = 5 THEN 'Friday'
            WHEN day_of_week_numeric = 6 THEN 'Saturday'
            WHEN day_of_week_numeric = 7 THEN 'Sunday'
        END AS day_of_week
    FROM 
        sales_with_day
)
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    d.day_of_week,
    SUM(ins.income) AS income
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

	
	