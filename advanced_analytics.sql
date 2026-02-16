-- Advanced Analytics for Retail Sales Analysis
-- Author: Data Analytics Portfolio
-- Description: Advanced SQL queries for deeper business insights

-- =====================================================
-- CUSTOMER SEGMENTATION & RFM ANALYSIS
-- =====================================================

-- RFM Analysis (Recency, Frequency, Monetary)
-- This helps segment customers based on their purchasing behavior
WITH customer_rfm AS (
    SELECT 
        customer_id,
        MAX(sale_date) as last_purchase_date,
        COUNT(DISTINCT transaction_id) as frequency,
        SUM(total_sale) as monetary_value,
        -- Calculate recency (days since last purchase from max date in dataset)
        (SELECT MAX(sale_date) FROM retail_sales) - MAX(sale_date) as recency_days
    FROM retail_sales
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT 
        customer_id,
        last_purchase_date,
        frequency,
        monetary_value,
        recency_days,
        -- Assign RFM scores (1-5 scale)
        NTILE(5) OVER (ORDER BY recency_days DESC) as recency_score,
        NTILE(5) OVER (ORDER BY frequency ASC) as frequency_score,
        NTILE(5) OVER (ORDER BY monetary_value ASC) as monetary_score
    FROM customer_rfm
)
SELECT 
    customer_id,
    recency_score,
    frequency_score,
    monetary_score,
    (recency_score + frequency_score + monetary_score) as rfm_total_score,
    CASE 
        WHEN (recency_score + frequency_score + monetary_score) >= 13 THEN 'Champions'
        WHEN (recency_score + frequency_score + monetary_score) >= 10 THEN 'Loyal Customers'
        WHEN (recency_score + frequency_score + monetary_score) >= 7 THEN 'Potential Loyalists'
        WHEN (recency_score + frequency_score + monetary_score) >= 5 THEN 'At Risk'
        ELSE 'Lost Customers'
    END as customer_segment,
    frequency as total_purchases,
    ROUND(monetary_value, 2) as lifetime_value
FROM rfm_scores
ORDER BY rfm_total_score DESC;

-- =====================================================
-- CUSTOMER RETENTION & REPEAT PURCHASE ANALYSIS
-- =====================================================

-- Identify repeat customers and their purchase patterns
WITH customer_purchase_counts AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT transaction_id) as total_purchases,
        COUNT(DISTINCT DATE_TRUNC('month', sale_date)) as active_months,
        MIN(sale_date) as first_purchase_date,
        MAX(sale_date) as last_purchase_date,
        SUM(total_sale) as total_spent,
        AVG(total_sale) as avg_transaction_value
    FROM retail_sales
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN total_purchases = 1 THEN 'One-time Customer'
        WHEN total_purchases BETWEEN 2 AND 5 THEN 'Occasional Customer'
        WHEN total_purchases BETWEEN 6 AND 10 THEN 'Regular Customer'
        ELSE 'VIP Customer'
    END as customer_type,
    COUNT(customer_id) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_lifetime_value,
    ROUND(AVG(avg_transaction_value), 2) as avg_order_value,
    ROUND(AVG(total_purchases), 2) as avg_purchase_frequency
FROM customer_purchase_counts
GROUP BY 
    CASE 
        WHEN total_purchases = 1 THEN 'One-time Customer'
        WHEN total_purchases BETWEEN 2 AND 5 THEN 'Occasional Customer'
        WHEN total_purchases BETWEEN 6 AND 10 THEN 'Regular Customer'
        ELSE 'VIP Customer'
    END
ORDER BY avg_lifetime_value DESC;

-- =====================================================
-- PRODUCT PERFORMANCE & PROFITABILITY ANALYSIS
-- =====================================================

-- Calculate profit margins and performance metrics by category
SELECT 
    category,
    COUNT(DISTINCT transaction_id) as total_transactions,
    SUM(quantity) as total_units_sold,
    ROUND(SUM(total_sale), 2) as total_revenue,
    ROUND(SUM(cogs), 2) as total_cost,
    ROUND(SUM(total_sale - cogs), 2) as total_profit,
    ROUND(((SUM(total_sale - cogs) / SUM(total_sale)) * 100), 2) as profit_margin_pct,
    ROUND(AVG(price_per_unit), 2) as avg_price_per_unit,
    ROUND(AVG(quantity), 2) as avg_quantity_per_transaction,
    ROUND(SUM(total_sale) / COUNT(DISTINCT transaction_id), 2) as avg_transaction_value
FROM retail_sales
GROUP BY category
ORDER BY total_profit DESC;

-- =====================================================
-- COHORT ANALYSIS - Monthly Customer Retention
-- =====================================================

-- Track customer retention by their first purchase month
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(sale_date)) as cohort_month
    FROM retail_sales
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT 
        c.cohort_month,
        DATE_TRUNC('month', r.sale_date) as activity_month,
        COUNT(DISTINCT r.customer_id) as active_customers
    FROM customer_cohorts c
    JOIN retail_sales r ON c.customer_id = r.customer_id
    GROUP BY c.cohort_month, DATE_TRUNC('month', r.sale_date)
)
SELECT 
    cohort_month,
    activity_month,
    active_customers,
    EXTRACT(MONTH FROM AGE(activity_month, cohort_month)) as months_since_first_purchase
FROM cohort_activity
ORDER BY cohort_month, activity_month;

-- =====================================================
-- REVENUE GROWTH ANALYSIS
-- =====================================================

-- Month-over-Month and Year-over-Year revenue growth
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', sale_date) as month,
        SUM(total_sale) as revenue,
        COUNT(DISTINCT transaction_id) as transactions,
        COUNT(DISTINCT customer_id) as unique_customers
    FROM retail_sales
    GROUP BY DATE_TRUNC('month', sale_date)
)
SELECT 
    month,
    ROUND(revenue, 2) as monthly_revenue,
    transactions,
    unique_customers,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2) as mom_revenue_change,
    ROUND(((revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month) * 100), 2) as mom_growth_pct,
    ROUND(revenue - LAG(revenue, 12) OVER (ORDER BY month), 2) as yoy_revenue_change,
    ROUND(((revenue - LAG(revenue, 12) OVER (ORDER BY month)) / LAG(revenue, 12) OVER (ORDER BY month) * 100), 2) as yoy_growth_pct
FROM monthly_revenue
ORDER BY month;

-- =====================================================
-- CUSTOMER LIFETIME VALUE (CLV) PREDICTION
-- =====================================================

-- Calculate average customer lifetime value metrics
WITH customer_metrics AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT transaction_id) as purchase_count,
        SUM(total_sale) as total_revenue,
        AVG(total_sale) as avg_order_value,
        MAX(sale_date) - MIN(sale_date) as customer_lifespan_days,
        MIN(sale_date) as first_purchase,
        MAX(sale_date) as last_purchase
    FROM retail_sales
    GROUP BY customer_id
)
SELECT 
    ROUND(AVG(total_revenue), 2) as avg_customer_lifetime_value,
    ROUND(AVG(avg_order_value), 2) as avg_order_value,
    ROUND(AVG(purchase_count), 2) as avg_purchases_per_customer,
    ROUND(AVG(customer_lifespan_days), 0) as avg_customer_lifespan_days,
    ROUND(AVG(total_revenue) / NULLIF(AVG(customer_lifespan_days), 0) * 30, 2) as avg_monthly_revenue_per_customer
FROM customer_metrics
WHERE customer_lifespan_days > 0;

-- =====================================================
-- TIME-BASED SALES PATTERNS
-- =====================================================

-- Analyze sales patterns by day of week and hour
SELECT 
    TO_CHAR(sale_date, 'Day') as day_of_week,
    EXTRACT(DOW FROM sale_date) as day_number,
    EXTRACT(HOUR FROM sale_time) as hour_of_day,
    COUNT(*) as transaction_count,
    ROUND(SUM(total_sale), 2) as total_revenue,
    ROUND(AVG(total_sale), 2) as avg_transaction_value
FROM retail_sales
GROUP BY TO_CHAR(sale_date, 'Day'), EXTRACT(DOW FROM sale_date), EXTRACT(HOUR FROM sale_time)
ORDER BY day_number, hour_of_day;

-- =====================================================
-- CUSTOMER DEMOGRAPHICS ANALYSIS
-- =====================================================

-- Analyze purchasing behavior by age groups and gender
WITH age_groups AS (
    SELECT 
        customer_id,
        gender,
        age,
        CASE 
            WHEN age < 25 THEN '18-24'
            WHEN age BETWEEN 25 AND 34 THEN '25-34'
            WHEN age BETWEEN 35 AND 44 THEN '35-44'
            WHEN age BETWEEN 45 AND 54 THEN '45-54'
            WHEN age BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65+'
        END as age_group,
        category,
        total_sale,
        quantity
    FROM retail_sales
)
SELECT 
    age_group,
    gender,
    COUNT(DISTINCT customer_id) as unique_customers,
    COUNT(*) as total_transactions,
    ROUND(SUM(total_sale), 2) as total_revenue,
    ROUND(AVG(total_sale), 2) as avg_transaction_value,
    ROUND(SUM(quantity), 0) as total_items_purchased
FROM age_groups
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- =====================================================
-- PRODUCT BASKET ANALYSIS
-- =====================================================

-- Identify most popular product categories purchased together
WITH customer_categories AS (
    SELECT 
        customer_id,
        transaction_id,
        category
    FROM retail_sales
)
SELECT 
    a.category as category_1,
    b.category as category_2,
    COUNT(DISTINCT a.customer_id) as customers_bought_both,
    COUNT(*) as times_bought_together
FROM customer_categories a
JOIN customer_categories b 
    ON a.customer_id = b.customer_id 
    AND a.category < b.category
GROUP BY a.category, b.category
HAVING COUNT(DISTINCT a.customer_id) > 5
ORDER BY customers_bought_both DESC;

-- =====================================================
-- SEASONAL TRENDS ANALYSIS
-- =====================================================

-- Analyze sales trends by season and quarter
SELECT 
    EXTRACT(YEAR FROM sale_date) as year,
    EXTRACT(QUARTER FROM sale_date) as quarter,
    CASE 
        WHEN EXTRACT(MONTH FROM sale_date) IN (12, 1, 2) THEN 'Winter'
        WHEN EXTRACT(MONTH FROM sale_date) IN (3, 4, 5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM sale_date) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END as season,
    category,
    COUNT(*) as transactions,
    ROUND(SUM(total_sale), 2) as revenue,
    ROUND(AVG(total_sale), 2) as avg_transaction_value,
    SUM(quantity) as units_sold
FROM retail_sales
GROUP BY 
    EXTRACT(YEAR FROM sale_date),
    EXTRACT(QUARTER FROM sale_date),
    CASE 
        WHEN EXTRACT(MONTH FROM sale_date) IN (12, 1, 2) THEN 'Winter'
        WHEN EXTRACT(MONTH FROM sale_date) IN (3, 4, 5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM sale_date) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END,
    category
ORDER BY year, quarter, category;

-- End of Advanced Analytics
