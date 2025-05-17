SELECT * FROM df_orders

DROP TABLE df_orders

CREATE TABLE df_orders (
    [order_id] int primary key,
    [order_date] date,
    [ship_mode] varchar(20),
    [segment] varchar(20),
    [country] varchar(20),
    [city] varchar(20),
    [state] varchar(20),
    [postal_code] varchar(20),
    [region] varchar(20),
    [category] varchar(20),
    [sub_category] varchar(20),
    [product_id] varchar(50),
    [quantity] int,
    [discount] decimal(7,2),
    [sale_price] decimal(7,2),
    [profit] decimal(7,2)
);

SELECT * FROM df_orders

--find top 10 highest reveue generating products 
SELECT TOP 10 product_id, SUM(sale_price) AS sales
FROM df_orders
GROUP BY product_id
ORDER BY sales DESC;

--find top 5 highest selling products in each region
WITH region_product_sales AS (
    SELECT 
        region,
        product_id,
        SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY region, product_id
)
SELECT *
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY sales DESC) AS rn
    FROM region_product_sales
) A
WHERE rn <= 5;


--find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023
WITH monthly_sales_summary AS (
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        SUM(sale_price) AS sales
    FROM df_orders
    WHERE YEAR(order_date) IN (2022, 2023)  -- Filter only for 2022 and 2023
    GROUP BY 
        YEAR(order_date), 
        MONTH(order_date)
)

SELECT 
    t1.order_month,
    t1.sales AS sales_2022,
    t2.sales AS sales_2023,
    ((t2.sales - t1.sales) / t1.sales) * 100 AS mom_growth_percentage
FROM 
    monthly_sales_summary t1
JOIN 
    monthly_sales_summary t2
    ON t1.order_month = t2.order_month
    AND t1.order_year = 2022  -- 2022 sales
    AND t2.order_year = 2023  -- 2023 sales
ORDER BY 
    t1.order_month;

--for each category which month had highest sales 
WITH monthly_sales_by_category AS (
    SELECT category,
        FORMAT(order_date, 'yyyyMM') AS order_year_month,
        SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY category, FORMAT(order_date, 'yyyyMM')
)
SELECT *
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS rn
    FROM monthly_sales_by_category
) a
WHERE rn = 1;


--which sub category had highest growth by profit in 2023 compare to 2022
WITH yearly_sales AS (
    SELECT 
        sub_category,
        YEAR(order_date) AS order_year,
        SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY sub_category, YEAR(order_date)
),
sales_comparison AS (
    SELECT 
        sub_category,
        SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
        SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
    FROM yearly_sales
    GROUP BY sub_category
)
SELECT TOP 1 
    sub_category,
    sales_2022,
    sales_2023,
    (sales_2023 - sales_2022) AS absolute_growth,
    ((sales_2023 - sales_2022) / NULLIF(sales_2022, 0)) * 100 AS growth_percentage -- This gives percentage growth
FROM sales_comparison
ORDER BY absolute_growth DESC;
