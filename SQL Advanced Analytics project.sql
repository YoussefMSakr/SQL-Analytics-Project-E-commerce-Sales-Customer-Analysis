----------------------------------------------------------SQL project Types----------------------------------------------------------
-------------------------------------------------------Advanced Data Analtics--------------------------------------------------------
----------------------------------------------------->> change over time Analysis <<-------------------------------------------------
SELECT 
       YEAR(order_date) AS sales_year,
       SUM(sales_amount) AS total_sales,
       COUNT(Distinct customer_key) as total_customers
       from [gold.fact_sales]
       WHERE order_date is NOT NULL
       group by YEAR(order_date)
       ORDER BY YEAR(order_date) ;
------------------------------------------------------------------------------------------------------
SELECT 
       YEAR(order_date) AS sales_year,
       MONTH(order_date) AS sales_month,
       SUM(sales_amount) AS total_sales,
       COUNT(Distinct customer_key) as total_customers
       from [gold.fact_sales]
       WHERE order_date is NOT NULL
       group by YEAR(order_date),MONTH(order_date)
       ORDER BY YEAR(order_date), MONTH(order_date)
-------------------------------------------------------Cumulative Analysis------------------------------
--1-calculate the total sales per month and the running total sales over time 
SELECT 
       sales_month,
       total_sales,
       SUM(total_sales) OVER (PARTITION BY sales_month ORDER BY sales_month) AS running_total_sales,
       AVG(avg_price) OVER (PARTITION BY sales_month ORDER BY sales_month) AS Moving_avg_price
from(

SELECT 
     DATETRUNC(YEAR, order_date) AS sales_month,
     SUM(sales_amount) AS total_sales ,
     AVG(price) AS avg_price   
from [gold.fact_sales]
WHERE order_date is NOT NULL
group by DATETRUNC(YEAR, order_date)
) as monthly_sales
------------------------------------------------------performance analysis--------------------------------
--it means comparing the current value to a target value and it help us ,easure success and compare performance
--1- analyze the yearly performance of products by comparing each products sales to both its average sales performance and the pervious years sales.

with yearly_product_sales as (
       SELECT 
              YEAR(s.order_date) AS order_year, 
       SUM(s.sales_amount) AS current_sales,
              p.product_name
       from [gold.fact_sales] s
       left join [gold.dim_products] p
       on s.product_key = p.product_key
       WHERE s.order_date is NOT NULL
       group by YEAR(s.order_date), p.product_name
)

SELECT 
       order_year,
       product_name,
       current_sales,
       AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
       current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS sales_difference,
       CASE 
              when current_sales - AVG(current_sales) OVER (PARTITION BY product_name)  > 0 then 'above average'
              when current_sales - AVG(current_sales) OVER (PARTITION BY product_name)  < 0 then 'below average'
              else 'average'
              END as AVG_change,
			  LAG(current_Sales) over (partition by product_name order by order_year ) AS Py_sales
from yearly_product_sales
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-------------------------------------------------Part to Whole Analysis-----------------------------------------------
--which category contributes the most to total sales
--1- calculate the total sales for each category and its percentage contribution to overall sales.
with category_sales AS (
SELECT 
       category,
       sum(sales_amount) AS total_sales
from [gold.fact_sales] s
Left join [gold.dim_products] p
on p.product_key = s.product_key
group by category
)
select
category,
total_Sales,
SUM(total_sales) over() overall_sales,
CONCAT(ROUND((CAST ( total_sales AS float) / SUM(total_sales) over () ) * 100 ,2), '%') AS percentage_total
from category_sales
order by percentage_total DESC
-------------------------------------------------------------------------------------------------------------------------------------------------------------------Data SEGMENTATION-----------------------------------------------
----------------------------------------------------Data SEGMENTATION-----------------------------------------------

--1- segment product into scot range and count how many products fall into each segment
With product_segments AS (

SELECT  
       product_key,
       product_name,
       cost,
       CASE 
              when cost < 100 then 'Below 100'
              when cost Between 100 and 500 then '100 and 500'
              when cost between 500 and 1000 then '500 and 1000'
              else 'Above 1000'
              end as cost_range
from [gold.dim_products]
)
SELECT
       cost_range,
       count(product_key) AS total_products
       from product_segments
       group by cost_range
       order by total_products DESC
-----------------------------------------------------------------------------------------------------------------

with customer_spending AS (
SELECT
c.customer_key,
SUM(s.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS customer_lifespan_months
from [gold.fact_sales] s
left join [gold.dim_customers] C
       on s.customer_key = C.customer_key
group by c.customer_key ) 

SELECT
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM(
SELECT
       customer_key,
       CASE 
              when customer_lifespan_months >= 12 And total_spending > 5000 then 'VIP'
              when customer_lifespan_months >= 12 And total_spending <= 5000 then 'regular'
              else 'NEW'
              end as customer_segment
              
from customer_spending  )t
GROUP BY customer_segment
ORDER BY total_customers DESC
 --------------------------------------------------customer Report-----------------------------------------------
--purpose : 
            -- this report consolidates key customer metrics and behaviors 
--highlights : 
--1- gathers essential fields such as names, ages , and transaction details
--2- segments customers into categries (VIP , regular, new) and age groups 
--3- aggregates custoemrlevel metrics : 
                -- total orders 
                -- average sales
                -- total quantity purchased
                -- total products
                -- life span in months
--4- calcualtes valuable KPIS :
                     -- recency (months since last order)
                     -- average order value
                     -- average monthly spend

CREATE VIEW dbo.[report_customer] AS
WITH base_query AS (
    SELECT 
        s.order_number,
        s.product_key,
        s.order_date,
        s.sales_amount,
        s.quantity,
        c.customer_key,
        c.customer_number,
        DATEDIFF(YEAR, c.birthdate, GETDATE()) AS customer_age,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name
    FROM [gold.fact_sales] AS s
    LEFT JOIN [gold.dim_customers] AS c 
        ON c.customer_key = s.customer_key
    WHERE s.order_date IS NOT NULL
),
customer_aggregation AS (
    SELECT 
        customer_key,
        customer_number,
        customer_age,  
        customer_name,
        COUNT(DISTINCT order_number)      AS total_orders,
        SUM(sales_amount)                 AS total_sales,
        SUM(quantity)                     AS total_quantity,
        COUNT(DISTINCT product_key)       AS total_products,
        MAX(order_date)                   AS last_order_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS customer_lifespan_months
    FROM base_query
    GROUP BY 
        customer_key,
        customer_number,
        customer_age,  
        customer_name
)
SELECT 
    customer_key,
    customer_number,
    customer_age,
    CASE 
        WHEN customer_age IS NULL           THEN 'unknown'       -- اختياري
        WHEN customer_age < 20              THEN 'under 20'
        WHEN customer_age BETWEEN 20 AND 29 THEN '20-29'
        WHEN customer_age BETWEEN 30 AND 39 THEN '30-39'
        WHEN customer_age BETWEEN 40 AND 49 THEN '40-49'
        WHEN customer_age BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60 and above'
    END AS age_group,
    CASE 
        WHEN customer_lifespan_months >= 12 AND total_sales > 5000 THEN 'vip'
        WHEN customer_lifespan_months >= 12 AND total_sales <= 5000 THEN 'regular'
        ELSE 'new'
    END AS customer_segment,
    last_order_date,
    DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency_months,
    customer_name,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    customer_lifespan_months,
    -- AOV
    CAST(total_sales AS DECIMAL(18,2)) / NULLIF(CAST(total_orders AS DECIMAL(18,2)), 0) AS avg_order_value,
    -- Avg monthly spend
    CAST(total_sales AS DECIMAL(18,2)) / NULLIF(CAST(customer_lifespan_months AS DECIMAL(18,2)), 0) AS avg_monthly_spend
FROM customer_aggregation;
--========================================================================================================================
select * 
from dbo.report_customer;

--========================================================================================================================
--========================================product Report==================================================================
create view dbo.product_Report AS
WITH product_performance AS (
    SELECT 
        p.product_name,
        p.category,
        p.Subcategory,
        p.cost,
        COUNT(DISTINCT s.order_number) AS total_orders,
        SUM(s.sales_amount) AS total_sales,
        SUM(s.quantity) AS total_quantity_sold,
        COUNT(DISTINCT customer_key) AS total_customers,
        DATEDIFF(month, MIN(order_date), MAX(order_date)) AS Lifespan_in_months,
        MAX(order_date) AS last_order_date
    FROM [gold.fact_sales] s
    LEFT JOIN [gold.dim_products] p
        ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY
        p.product_name,
        p.category,
        p.Subcategory,
        p.cost
),
final_report AS (
    SELECT 
        product_name,
        category,
        Subcategory,
        cost,
        total_orders,
        total_sales,
        total_quantity_sold,
        total_customers,
        Lifespan_in_months,
        DATEDIFF(month, last_order_date, GETDATE()) AS recency_in_months,
        CASE
            WHEN total_sales > 20000 THEN 'High-performance'
            WHEN total_sales BETWEEN 15000 AND 19000 THEN 'MID-range'
            ELSE 'Low-performance'
        END AS product_segment
    FROM product_performance
)
SELECT 
    product_name,
    category,
    Subcategory,
    cost,
    total_orders,
    total_sales,
    total_quantity_sold,
    total_customers,
    Lifespan_in_months,
    recency_in_months,
    product_segment,
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_Revenue,
    CASE 
        WHEN Lifespan_in_months = 0 THEN total_sales
        ELSE total_sales / Lifespan_in_months
    END AS avg_monthly_revenue
FROM final_report;
--=================================================================================================================
select *  
from dbo.product_report
--=================================================================================================================