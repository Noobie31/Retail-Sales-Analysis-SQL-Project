-- Data Quality Checks for Retail Sales Analysis
-- Author: Data Analytics Portfolio
-- Description: Comprehensive data validation and quality assurance queries

-- =====================================================
-- COMPLETENESS CHECKS
-- =====================================================

-- Check for NULL values across all critical columns
SELECT 
    'transaction_id' as column_name,
    COUNT(*) as total_records,
    COUNT(transaction_id) as non_null_count,
    COUNT(*) - COUNT(transaction_id) as null_count,
    ROUND((COUNT(transaction_id)::DECIMAL / COUNT(*)) * 100, 2) as completeness_pct
FROM retail_sales
UNION ALL
SELECT 
    'sale_date',
    COUNT(*),
    COUNT(sale_date),
    COUNT(*) - COUNT(sale_date),
    ROUND((COUNT(sale_date)::DECIMAL / COUNT(*)) * 100, 2)
FROM retail_sales
UNION ALL
SELECT 
    'customer_id',
    COUNT(*),
    COUNT(customer_id),
    COUNT(*) - COUNT(customer_id),
    ROUND((COUNT(customer_id)::DECIMAL / COUNT(*)) * 100, 2)
FROM retail_sales
UNION ALL
SELECT 
    'category',
    COUNT(*),
    COUNT(category),
    COUNT(*) - COUNT(category),
    ROUND((COUNT(category)::DECIMAL / COUNT(*)) * 100, 2)
FROM retail_sales
UNION ALL
SELECT 
    'total_sale',
    COUNT(*),
    COUNT(total_sale),
    COUNT(*) - COUNT(total_sale),
    ROUND((COUNT(total_sale)::DECIMAL / COUNT(*)) * 100, 2)
FROM retail_sales;

-- =====================================================
-- DUPLICATE DETECTION
-- =====================================================

-- Check for duplicate transaction IDs
SELECT 
    transaction_id,
    COUNT(*) as occurrence_count
FROM retail_sales
GROUP BY transaction_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

-- Check for potential duplicate transactions (same customer, date, time, amount)
SELECT 
    customer_id,
    sale_date,
    sale_time,
    total_sale,
    COUNT(*) as duplicate_count
FROM retail_sales
GROUP BY customer_id, sale_date, sale_time, total_sale
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- =====================================================
-- DATA CONSISTENCY CHECKS
-- =====================================================

-- Verify that total_sale = quantity * price_per_unit
SELECT 
    transaction_id,
    quantity,
    price_per_unit,
    total_sale,
    ROUND(quantity * price_per_unit, 2) as calculated_total,
    ROUND(total_sale - (quantity * price_per_unit), 2) as difference
FROM retail_sales
WHERE ABS(total_sale - (quantity * price_per_unit)) > 0.01
ORDER BY ABS(difference) DESC;

-- Check if COGS is reasonable compared to total_sale (should be less than total_sale)
SELECT 
    transaction_id,
    total_sale,
    cogs,
    ROUND(total_sale - cogs, 2) as profit,
    ROUND((cogs / NULLIF(total_sale, 0)) * 100, 2) as cogs_percentage
FROM retail_sales
WHERE cogs >= total_sale OR cogs < 0
ORDER BY transaction_id;

-- =====================================================
-- RANGE AND VALIDITY CHECKS
-- =====================================================

-- Check for invalid age values
SELECT 
    'Invalid Age' as issue_type,
    COUNT(*) as record_count
FROM retail_sales
WHERE age < 0 OR age > 120 OR age IS NULL
UNION ALL
-- Check for invalid quantities
SELECT 
    'Invalid Quantity',
    COUNT(*)
FROM retail_sales
WHERE quantity <= 0 OR quantity IS NULL
UNION ALL
-- Check for invalid prices
SELECT 
    'Invalid Price',
    COUNT(*)
FROM retail_sales
WHERE price_per_unit <= 0 OR price_per_unit IS NULL
UNION ALL
-- Check for invalid total_sale
SELECT 
    'Invalid Total Sale',
    COUNT(*)
FROM retail_sales
WHERE total_sale <= 0 OR total_sale IS NULL
UNION ALL
-- Check for future dates
SELECT 
    'Future Date',
    COUNT(*)
FROM retail_sales
WHERE sale_date > CURRENT_DATE;

-- =====================================================
-- STATISTICAL OUTLIER DETECTION
-- =====================================================

-- Detect outliers in total_sale using IQR method
WITH sale_stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_sale) as q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_sale) as q3,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_sale) - 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_sale) as iqr
    FROM retail_sales
)
SELECT 
    r.transaction_id,
    r.customer_id,
    r.category,
    r.total_sale,
    ROUND(s.q1, 2) as q1_threshold,
    ROUND(s.q3, 2) as q3_threshold,
    ROUND(s.q1 - (1.5 * s.iqr), 2) as lower_bound,
    ROUND(s.q3 + (1.5 * s.iqr), 2) as upper_bound,
    CASE 
        WHEN r.total_sale < (s.q1 - (1.5 * s.iqr)) THEN 'Low Outlier'
        WHEN r.total_sale > (s.q3 + (1.5 * s.iqr)) THEN 'High Outlier'
    END as outlier_type
FROM retail_sales r
CROSS JOIN sale_stats s
WHERE r.total_sale < (s.q1 - (1.5 * s.iqr)) 
   OR r.total_sale > (s.q3 + (1.5 * s.iqr))
ORDER BY r.total_sale DESC;

-- =====================================================
-- REFERENTIAL INTEGRITY CHECKS
-- =====================================================

-- Check for orphaned or inconsistent customer records
WITH customer_summary AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT gender) as gender_variations,
        COUNT(DISTINCT age) as age_variations,
        STRING_AGG(DISTINCT gender, ', ') as genders,
        STRING_AGG(DISTINCT age::TEXT, ', ') as ages
    FROM retail_sales
    GROUP BY customer_id
)
SELECT 
    customer_id,
    gender_variations,
    age_variations,
    genders,
    ages
FROM customer_summary
WHERE gender_variations > 1 OR age_variations > 1
ORDER BY customer_id;

-- =====================================================
-- TEMPORAL CONSISTENCY CHECKS
-- =====================================================

-- Check for transactions with invalid time sequences
SELECT 
    customer_id,
    transaction_id,
    sale_date,
    sale_time,
    LAG(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date, sale_time) as prev_date,
    LAG(sale_time) OVER (PARTITION BY customer_id ORDER BY sale_date, sale_time) as prev_time
FROM retail_sales
WHERE sale_date IS NOT NULL AND sale_time IS NOT NULL
ORDER BY customer_id, sale_date, sale_time;

-- Check for unusual transaction patterns (multiple transactions same customer same minute)
SELECT 
    customer_id,
    sale_date,
    DATE_TRUNC('minute', sale_time) as sale_minute,
    COUNT(*) as transactions_in_minute
FROM retail_sales
GROUP BY customer_id, sale_date, DATE_TRUNC('minute', sale_time)
HAVING COUNT(*) > 1
ORDER BY transactions_in_minute DESC;

-- =====================================================
-- CATEGORY AND GENDER VALIDATION
-- =====================================================

-- Check for invalid or unexpected category values
SELECT 
    category,
    COUNT(*) as record_count,
    ROUND(AVG(total_sale), 2) as avg_sale,
    MIN(sale_date) as first_appearance,
    MAX(sale_date) as last_appearance
FROM retail_sales
GROUP BY category
ORDER BY record_count DESC;

-- Check for invalid or unexpected gender values
SELECT 
    gender,
    COUNT(*) as record_count,
    COUNT(DISTINCT customer_id) as unique_customers
FROM retail_sales
GROUP BY gender
ORDER BY record_count DESC;

-- =====================================================
-- DATA DISTRIBUTION ANALYSIS
-- =====================================================

-- Analyze distribution of transactions across time periods
SELECT 
    EXTRACT(YEAR FROM sale_date) as year,
    EXTRACT(MONTH FROM sale_date) as month,
    COUNT(*) as transaction_count,
    COUNT(DISTINCT customer_id) as unique_customers,
    ROUND(AVG(total_sale), 2) as avg_sale
FROM retail_sales
GROUP BY EXTRACT(YEAR FROM sale_date), EXTRACT(MONTH FROM sale_date)
ORDER BY year, month;

-- Check for unusual gaps in transaction dates
WITH date_series AS (
    SELECT 
        sale_date,
        LEAD(sale_date) OVER (ORDER BY sale_date) as next_date,
        LEAD(sale_date) OVER (ORDER BY sale_date) - sale_date as days_gap
    FROM (SELECT DISTINCT sale_date FROM retail_sales) t
)
SELECT 
    sale_date,
    next_date,
    days_gap
FROM date_series
WHERE days_gap > 7  -- Flag gaps larger than 7 days
ORDER BY days_gap DESC;

-- =====================================================
-- SUMMARY DATA QUALITY REPORT
-- =====================================================

-- Overall data quality summary
SELECT 
    'Total Records' as metric,
    COUNT(*)::TEXT as value
FROM retail_sales
UNION ALL
SELECT 
    'Unique Customers',
    COUNT(DISTINCT customer_id)::TEXT
FROM retail_sales
UNION ALL
SELECT 
    'Date Range',
    MIN(sale_date)::TEXT || ' to ' || MAX(sale_date)::TEXT
FROM retail_sales
UNION ALL
SELECT 
    'Unique Categories',
    COUNT(DISTINCT category)::TEXT
FROM retail_sales
UNION ALL
SELECT 
    'Total Revenue',
    '$' || ROUND(SUM(total_sale), 2)::TEXT
FROM retail_sales
UNION ALL
SELECT 
    'Avg Transaction Value',
    '$' || ROUND(AVG(total_sale), 2)::TEXT
FROM retail_sales
UNION ALL
SELECT 
    'Records with NULL values',
    COUNT(*)::TEXT
FROM retail_sales
WHERE transaction_id IS NULL OR sale_date IS NULL OR customer_id IS NULL 
   OR category IS NULL OR total_sale IS NULL;

-- End of Data Quality Checks
