-- SQL Retail Sales Analysis - P1
CREATE DATABASE sql_project_p2;


-- Create TABLE
DROP TABLE IF EXISTS retail_sales;
CREATE TABLE retail_sales
            (
                transaction_id INT PRIMARY KEY,	
                sale_date DATE,	 
                sale_time TIME,	
                customer_id	INT,
                gender	VARCHAR(15),
                age	INT,
                category VARCHAR(15),	
                quantity	INT,
                price_per_unit FLOAT,	
                cogs	FLOAT,
                total_sale FLOAT
            );

SELECT * FROM retail_sales
LIMIT 10


    

SELECT 
    COUNT(*) 
FROM retail_sales

-- Data Cleaning
SELECT * FROM retail_sales
WHERE transactions_id IS NULL

SELECT * FROM retail_sales
WHERE sale_date IS NULL

SELECT * FROM retail_sales
WHERE sale_time IS NULL

SELECT * FROM retail_sales
WHERE 
    transaction_id IS NULL
    OR
    sale_date IS NULL
    OR 
    sale_time IS NULL
    OR
    gender IS NULL
    OR
    category IS NULL
    OR
    quantity IS NULL
    OR
    cogs IS NULL
    OR
    total_sale IS NULL;
    
-- 
DELETE FROM retail_sales
WHERE 
    transaction_id IS NULL
    OR
    sale_date IS NULL
    OR 
    sale_time IS NULL
    OR
    gender IS NULL
    OR
    category IS NULL
    OR
    quantity IS NULL
    OR
    cogs IS NULL
    OR
    total_sale IS NULL;
    
-- Data Exploration

-- How many sales we have?
SELECT COUNT(*) as total_sale FROM retail_sales

-- How many uniuque customers we have ?

SELECT COUNT(DISTINCT customer_id) as total_sale FROM retail_sales



SELECT DISTINCT category FROM retail_sales


-- Data Analysis & Business Key Problems & Answers

-- My Analysis & Findings
-- Q.1 Write a SQL query to retrieve all columns for sales made on '2022-11-05
-- Q.2 Write a SQL query to retrieve all transactions where the category is 'Clothing' and the quantity sold is more than 10 in the month of Nov-2022
-- Q.3 Write a SQL query to calculate the total sales (total_sale) for each category.
-- Q.4 Write a SQL query to find the average age of customers who purchased items from the 'Beauty' category.
-- Q.5 Write a SQL query to find all transactions where the total_sale is greater than 1000.
-- Q.6 Write a SQL query to find the total number of transactions (transaction_id) made by each gender in each category.
-- Q.7 Write a SQL query to calculate the average sale for each month. Find out best selling month in each year
-- Q.8 Write a SQL query to find the top 5 customers based on the highest total sales 
-- Q.9 Write a SQL query to find the number of unique customers who purchased items from each category.
-- Q.10 Write a SQL query to create each shift and number of orders (Example Morning <=12, Afternoon Between 12 & 17, Evening >17)



 -- Q.1 Write a SQL query to retrieve all columns for sales made on '2022-11-05

SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05';


-- Q.2 Write a SQL query to retrieve all transactions where the category is 'Clothing' and the quantity sold is more than 4 in the month of Nov-2022

SELECT 
  *
FROM retail_sales
WHERE 
    category = 'Clothing'
    AND 
    TO_CHAR(sale_date, 'YYYY-MM') = '2022-11'
    AND
    quantity >= 4


-- Q.3 Write a SQL query to calculate the total sales (total_sale) for each category.

SELECT 
    category,
    SUM(total_sale) as net_sale,
    COUNT(*) as total_orders
FROM retail_sales
GROUP BY 1

-- Q.4 Write a SQL query to find the average age of customers who purchased items from the 'Beauty' category.

SELECT
    ROUND(AVG(age), 2) as avg_age
FROM retail_sales
WHERE category = 'Beauty'


-- Q.5 Write a SQL query to find all transactions where the total_sale is greater than 1000.

SELECT * FROM retail_sales
WHERE total_sale > 1000


-- Q.6 Write a SQL query to find the total number of transactions (transaction_id) made by each gender in each category.

SELECT 
    category,
    gender,
    COUNT(*) as total_trans
FROM retail_sales
GROUP 
    BY 
    category,
    gender
ORDER BY 1


-- Q.7 Write a SQL query to calculate the average sale for each month. Find out best selling month in each year

SELECT 
       year,
       month,
    avg_sale
FROM 
(    
SELECT 
    EXTRACT(YEAR FROM sale_date) as year,
    EXTRACT(MONTH FROM sale_date) as month,
    AVG(total_sale) as avg_sale,
    RANK() OVER(PARTITION BY EXTRACT(YEAR FROM sale_date) ORDER BY AVG(total_sale) DESC) as rank
FROM retail_sales
GROUP BY 1, 2
) as t1
WHERE rank = 1
    
-- ORDER BY 1, 3 DESC

-- Q.8 Write a SQL query to find the top 5 customers based on the highest total sales 

SELECT 
    customer_id,
    SUM(total_sale) as total_sales
FROM retail_sales
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5

-- Q.9 Write a SQL query to find the number of unique customers who purchased items from each category.


SELECT 
    category,    
    COUNT(DISTINCT customer_id) as cnt_unique_cs
FROM retail_sales
GROUP BY category



-- Q.10 Write a SQL query to create each shift and number of orders (Example Morning <12, Afternoon Between 12 & 17, Evening >17)

WITH hourly_sale
AS
(
SELECT *,
    CASE
        WHEN EXTRACT(HOUR FROM sale_time) < 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END as shift
FROM retail_sales
)
SELECT 
    shift,
    COUNT(*) as total_orders    
FROM hourly_sale
GROUP BY shift

-- End of basic queries

-- =====================================================
-- ADDITIONAL ADVANCED QUERIES
-- =====================================================

-- Q.11 Calculate customer retention rate (customers who made repeat purchases)
SELECT 
    COUNT(DISTINCT CASE WHEN purchase_count > 1 THEN customer_id END) as repeat_customers,
    COUNT(DISTINCT customer_id) as total_customers,
    ROUND((COUNT(DISTINCT CASE WHEN purchase_count > 1 THEN customer_id END)::DECIMAL / 
           COUNT(DISTINCT customer_id)) * 100, 2) as retention_rate_pct
FROM (
    SELECT customer_id, COUNT(*) as purchase_count
    FROM retail_sales
    GROUP BY customer_id
) customer_purchases;

-- Q.12 Find the most profitable product category by calculating profit margin
SELECT 
    category,
    ROUND(SUM(total_sale), 2) as total_revenue,
    ROUND(SUM(cogs), 2) as total_cost,
    ROUND(SUM(total_sale - cogs), 2) as total_profit,
    ROUND(((SUM(total_sale - cogs) / SUM(total_sale)) * 100), 2) as profit_margin_pct
FROM retail_sales
GROUP BY category
ORDER BY profit_margin_pct DESC;

-- Q.13 Identify customers who haven't purchased in the last 90 days (churn risk)
WITH last_purchase AS (
    SELECT 
        customer_id,
        MAX(sale_date) as last_purchase_date,
        (SELECT MAX(sale_date) FROM retail_sales) - MAX(sale_date) as days_since_purchase
    FROM retail_sales
    GROUP BY customer_id
)
SELECT 
    customer_id,
    last_purchase_date,
    days_since_purchase
FROM last_purchase
WHERE days_since_purchase > 90
ORDER BY days_since_purchase DESC;

-- Q.14 Calculate year-over-year growth by category
WITH yearly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM sale_date) as year,
        category,
        SUM(total_sale) as annual_revenue
    FROM retail_sales
    GROUP BY EXTRACT(YEAR FROM sale_date), category
)
SELECT 
    year,
    category,
    ROUND(annual_revenue, 2) as revenue,
    ROUND(annual_revenue - LAG(annual_revenue) OVER (PARTITION BY category ORDER BY year), 2) as yoy_change,
    ROUND(((annual_revenue - LAG(annual_revenue) OVER (PARTITION BY category ORDER BY year)) / 
           LAG(annual_revenue) OVER (PARTITION BY category ORDER BY year) * 100), 2) as yoy_growth_pct
FROM yearly_sales
ORDER BY category, year;

-- Q.15 Find the average time between purchases for repeat customers
WITH customer_purchases AS (
    SELECT 
        customer_id,
        sale_date,
        LEAD(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date) as next_purchase_date
    FROM retail_sales
)
SELECT 
    ROUND(AVG(next_purchase_date - sale_date), 2) as avg_days_between_purchases
FROM customer_purchases
WHERE next_purchase_date IS NOT NULL;

-- Q.16 Identify top performing days of the week by revenue
SELECT 
    TO_CHAR(sale_date, 'Day') as day_of_week,
    EXTRACT(DOW FROM sale_date) as day_number,
    COUNT(*) as total_transactions,
    ROUND(SUM(total_sale), 2) as total_revenue,
    ROUND(AVG(total_sale), 2) as avg_transaction_value
FROM retail_sales
GROUP BY TO_CHAR(sale_date, 'Day'), EXTRACT(DOW FROM sale_date)
ORDER BY total_revenue DESC;

-- Q.17 Calculate customer lifetime value (CLV) for top customers
SELECT 
    customer_id,
    COUNT(DISTINCT transaction_id) as total_purchases,
    ROUND(SUM(total_sale), 2) as lifetime_value,
    ROUND(AVG(total_sale), 2) as avg_order_value,
    MIN(sale_date) as first_purchase,
    MAX(sale_date) as last_purchase,
    MAX(sale_date) - MIN(sale_date) as customer_lifespan_days
FROM retail_sales
GROUP BY customer_id
ORDER BY lifetime_value DESC
LIMIT 20;

-- Q.18 Analyze sales performance by age demographics
SELECT 
    CASE 
        WHEN age < 25 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END as age_group,
    COUNT(DISTINCT customer_id) as unique_customers,
    COUNT(*) as total_transactions,
    ROUND(SUM(total_sale), 2) as total_revenue,
    ROUND(AVG(total_sale), 2) as avg_transaction_value
FROM retail_sales
GROUP BY 
    CASE 
        WHEN age < 25 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END
ORDER BY total_revenue DESC;

-- End of project

