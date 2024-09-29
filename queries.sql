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
        sales AS s
    LEFT JOIN
        products AS p ON s.product_id = p.product_id
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
        sales AS s
    GROUP BY
        s.sales_person_id
)

SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COALESCE(sc.total_sales_count, 0) AS total_operations,
    FLOOR(id.total_income) AS total_income
FROM
    income_data AS id
LEFT JOIN
    sales_count AS sc ON id.sales_person_id = sc.sales_person_id
LEFT JOIN
    employees AS e ON id.sales_person_id = e.employee_id
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
        sales AS s
    LEFT JOIN
        products AS p ON s.product_id = p.product_id
    GROUP BY
        s.sales_person_id
),

total_avg_income AS (
    SELECT AVG(average_income) AS overall_average_income
    FROM
        avg_income
)

SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    FLOOR(ai.average_income) AS average_income
FROM
    avg_income AS ai
LEFT JOIN
    employees AS e ON ai.sales_person_id = e.employee_id
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
        sales AS s
    LEFT JOIN
        products AS p ON s.product_id = p.product_id
    GROUP BY
        s.sales_id
),

sales_with_day AS (
    SELECT
        s.sales_id,
        EXTRACT(ISODOW FROM s.sale_date) AS day_of_week_numeric
    FROM
        sales AS s
),

sales_with_day_text AS (
    SELECT
        sales_id,
        day_of_week_numeric,
        CASE
            WHEN day_of_week_numeric = 1 THEN 'monday'
            WHEN day_of_week_numeric = 2 THEN 'tuesday  '
            WHEN day_of_week_numeric = 3 THEN 'wednesday'
            WHEN day_of_week_numeric = 4 THEN 'thursday '
            WHEN day_of_week_numeric = 5 THEN 'friday'
            WHEN day_of_week_numeric = 6 THEN 'saturday '
            WHEN day_of_week_numeric = 7 THEN 'sunday'
        END AS day_of_week
    FROM
        sales_with_day
),

sellernames AS (
    SELECT
        s.sales_id,
        CONCAT(e.first_name, ' ', e.last_name) AS seller
    FROM
        sales AS s
    LEFT JOIN
        employees AS e ON s.sales_person_id = e.employee_id
)

SELECT
    sn.seller,
    d.day_of_week,
    FLOOR(SUM(ins.income)) AS income
FROM
    sellernames AS sn
LEFT JOIN
    sales AS s ON sn.sales_id = s.sales_id
LEFT JOIN
    sales_with_day_text AS d ON s.sales_id = d.sales_id
LEFT JOIN
    income_sales AS ins ON s.sales_id = ins.sales_id
GROUP BY
    d.day_of_week_numeric, sn.seller, d.day_of_week
ORDER BY
    d.day_of_week_numeric, sn.seller;
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
        sales AS s
    LEFT JOIN
        products AS p ON s.product_id = p.product_id
    GROUP BY
        s.customer_id
),

selling_month AS (
    SELECT
        s.sales_id,
        EXTRACT(YEAR FROM s.sale_date)
        AS yearr,
        EXTRACT(MONTH FROM s.sale_date)
        AS monthh
    FROM
        sales AS s
)

SELECT
    CONCAT(sm.yearr, '-', LPAD(sm.monthh::text, 2, '0')) AS selling_month,
    COUNT(DISTINCT s.customer_id) AS unique_customers,
    FLOOR(SUM(inc.total_income)) AS total_income
FROM
    sales AS s
LEFT JOIN
    selling_month AS sm ON s.sales_id = sm.sales_id
LEFT JOIN
    incomes AS inc ON s.customer_id = inc.customer_id
GROUP BY
    sm.yearr, sm.monthh
ORDER BY
    sm.yearr, sm.monthh;

/*
Получение информации о покупателях, первая
покупка которых была в ходе проведения акций
*/
WITH first_purchase AS (
    SELECT
        sl.customer_id,
        MIN(sl.sale_date) AS first_purchase_date
    FROM
        sales AS sl
    JOIN
        products AS pr ON sl.product_id = pr.product_id
    WHERE
        pr.price = 0
    GROUP BY
        sl.customer_id
),

customer_info AS (
    SELECT
        ctmr.customer_id,
        CONCAT(ctmr.first_name, ' ', ctmr.last_name) AS customer_name
    FROM
        customers AS ctmr
),

employee_info AS (
    SELECT
        emp.employee_id,
        CONCAT(emp.first_name, ' ', emp.last_name) AS seller_name
    FROM
        employees AS emp
),

purchase_info AS (
    SELECT DISTINCT
        ci.customer_name AS customer_name,
        fp.first_purchase_date AS first_purchase_date,
        ei.seller_name AS seller_name
    FROM
        first_purchase AS fp
    JOIN
        sales AS s
        ON 
            fp.customer_id = s.customer_id
            AND fp.first_purchase_date = s.sale_date
    LEFT JOIN
        customer_info AS ci ON s.customer_id = ci.customer_id
    LEFT JOIN
        employee_info AS ei ON s.sales_person_id = ei.employee_id
    LEFT JOIN
        products AS p ON s.product_id = p.product_id
    WHERE
        p.price = 0
)

SELECT
    pi.customer_name,
    pi.first_purchase_date,
    pi.seller_name
FROM
    purchase_info AS pi
ORDER BY
    pi.customer_name, pi.first_purchase_date;
