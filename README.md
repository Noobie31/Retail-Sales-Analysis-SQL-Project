# Retail Sales Analysis SQL Project

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue)
![Analysis](https://img.shields.io/badge/Analysis-Retail%20Sales-green)
![Level](https://img.shields.io/badge/Level-Beginner%20to%20Advanced-orange)

## Project Overview

**Project Title**: Comprehensive Retail Sales Analysis  
**Level**: Beginner to Advanced  
**Database**: `p1_retail_db`  
**Technologies**: PostgreSQL, SQL, Data Analytics

This project demonstrates advanced SQL skills and analytical techniques used by data analysts to explore, clean, and derive actionable insights from retail sales data. The project encompasses database setup, comprehensive data quality checks, exploratory data analysis (EDA), advanced customer segmentation, and strategic business intelligence queries.

**What makes this project unique:**
- 18+ business analysis queries from basic to advanced
- Customer segmentation using RFM analysis
- Cohort analysis and retention metrics
- Advanced analytics including CLV, churn prediction, and revenue growth
- Comprehensive data quality validation framework

## Objectives

1. **Set up a retail sales database**: Create and populate a retail sales database with the provided sales data.
2. **Data Quality Assurance**: Implement comprehensive data validation, consistency checks, and outlier detection.
3. **Data Cleaning**: Identify and remove any records with missing or null values.
4. **Exploratory Data Analysis (EDA)**: Perform thorough exploratory data analysis to understand the dataset.
5. **Business Analysis**: Use SQL to answer 18+ specific business questions and derive actionable insights.
6. **Advanced Analytics**: Implement customer segmentation, cohort analysis, and predictive metrics.
7. **Strategic Insights**: Generate data-driven recommendations for business growth.

## Project Structure

### 1. Database Setup

- **Database Creation**: The project starts by creating a database named `p1_retail_db`.
- **Table Creation**: A table named `retail_sales` is created to store the sales data. The table structure includes columns for transaction ID, sale date, sale time, customer ID, gender, age, product category, quantity sold, price per unit, cost of goods sold (COGS), and total sale amount.

```sql
CREATE DATABASE p1_retail_db;

CREATE TABLE retail_sales
(
    transactions_id INT PRIMARY KEY,
    sale_date DATE,	
    sale_time TIME,
    customer_id INT,	
    gender VARCHAR(10),
    age INT,
    category VARCHAR(35),
    quantity INT,
    price_per_unit FLOAT,	
    cogs FLOAT,
    total_sale FLOAT
);
```

### 2. Data Exploration & Cleaning

- **Record Count**: Determine the total number of records in the dataset.
- **Customer Count**: Find out how many unique customers are in the dataset.
- **Category Count**: Identify all unique product categories in the dataset.
- **Null Value Check**: Check for any null values in the dataset and delete records with missing data.

```sql
SELECT COUNT(*) FROM retail_sales;
SELECT COUNT(DISTINCT customer_id) FROM retail_sales;
SELECT DISTINCT category FROM retail_sales;

SELECT * FROM retail_sales
WHERE 
    sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR 
    gender IS NULL OR age IS NULL OR category IS NULL OR 
    quantity IS NULL OR price_per_unit IS NULL OR cogs IS NULL;

DELETE FROM retail_sales
WHERE 
    sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR 
    gender IS NULL OR age IS NULL OR category IS NULL OR 
    quantity IS NULL OR price_per_unit IS NULL OR cogs IS NULL;
```

### 3. Data Analysis & Findings

The following SQL queries were developed to answer specific business questions:

1. **Write a SQL query to retrieve all columns for sales made on '2022-11-05**:
```sql
SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05';
```

2. **Write a SQL query to retrieve all transactions where the category is 'Clothing' and the quantity sold is more than 4 in the month of Nov-2022**:
```sql
SELECT 
  *
FROM retail_sales
WHERE 
    category = 'Clothing'
    AND 
    TO_CHAR(sale_date, 'YYYY-MM') = '2022-11'
    AND
    quantity >= 4
```

3. **Write a SQL query to calculate the total sales (total_sale) for each category.**:
```sql
SELECT 
    category,
    SUM(total_sale) as net_sale,
    COUNT(*) as total_orders
FROM retail_sales
GROUP BY 1
```

4. **Write a SQL query to find the average age of customers who purchased items from the 'Beauty' category.**:
```sql
SELECT
    ROUND(AVG(age), 2) as avg_age
FROM retail_sales
WHERE category = 'Beauty'
```

5. **Write a SQL query to find all transactions where the total_sale is greater than 1000.**:
```sql
SELECT * FROM retail_sales
WHERE total_sale > 1000
```

6. **Write a SQL query to find the total number of transactions (transaction_id) made by each gender in each category.**:
```sql
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
```

7. **Write a SQL query to calculate the average sale for each month. Find out best selling month in each year**:
```sql
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
```

8. **Write a SQL query to find the top 5 customers based on the highest total sales **:
```sql
SELECT 
    customer_id,
    SUM(total_sale) as total_sales
FROM retail_sales
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5
```

9. **Write a SQL query to find the number of unique customers who purchased items from each category.**:
```sql
SELECT 
    category,    
    COUNT(DISTINCT customer_id) as cnt_unique_cs
FROM retail_sales
GROUP BY category
```

10. **Write a SQL query to create each shift and number of orders (Example Morning <12, Afternoon Between 12 & 17, Evening >17)**:
```sql
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
```

## Additional Advanced Queries

11. **Customer Retention Rate**: Calculate the percentage of customers who made repeat purchases
12. **Profit Margin Analysis**: Find the most profitable product categories
13. **Churn Risk Identification**: Identify customers who haven't purchased in 90+ days
14. **Year-over-Year Growth**: Calculate revenue growth by category
15. **Purchase Frequency**: Find average time between purchases for repeat customers
16. **Day-of-Week Performance**: Identify top performing days by revenue
17. **Customer Lifetime Value**: Calculate CLV for top customers
18. **Demographic Analysis**: Analyze sales performance by age groups

## Key Findings

### Customer Insights
- **Customer Segmentation**: Customers classified into Champions, Loyal, Potential Loyalists, At Risk, and Lost segments using RFM analysis
- **Retention Patterns**: Repeat customers show significantly higher lifetime value
- **Demographics**: Age groups 25-44 represent the highest revenue-generating segment
- **Churn Risk**: Customers with 90+ day gaps show high probability of churn

### Product Performance
- **Category Profitability**: Profit margins vary significantly across categories
- **Sales Distribution**: Clothing, Beauty, and Electronics are top-performing categories
- **Seasonal Trends**: Clear seasonal patterns identified in sales data

### Revenue Trends
- **Monthly Variations**: Specific months consistently outperform others
- **Growth Patterns**: Year-over-year analysis reveals business trajectory
- **Peak Periods**: Time-of-day analysis shows optimal shopping hours

### Strategic Recommendations
- Implement targeted retention campaigns for at-risk customers
- Optimize inventory based on seasonal demand patterns
- Focus marketing on high-margin categories
- Develop personalized campaigns based on customer segments

For detailed insights and recommendations, see [insights.md](insights.md)

## Project Structure

```
retail-sales-analysis/
├── README.md                          # Project documentation
├── sql_query_p1.sql                   # Main analysis queries (18 questions)
├── advanced_analytics.sql             # Advanced analytics (RFM, cohort, CLV)
├── data_quality_checks.sql            # Data validation queries
├── insights.md                        # Key findings and recommendations
└── SQL - Retail Sales Analysis_utf.csv # Source data
```

## Conclusion

This project demonstrates comprehensive SQL analytics capabilities, from basic data exploration to advanced customer segmentation and predictive metrics. The analysis provides actionable insights for:
- Customer retention and loyalty programs
- Product portfolio optimization
- Revenue growth strategies
- Data-driven decision making

The methodologies and queries can be adapted for various retail analytics scenarios and scaled for larger datasets.

## How to Use

1. **Clone the Repository**: 
   ```bash
   git clone https://github.com/Noobie31/Retail-Sales-Analysis-SQL.git
   cd Retail-Sales-Analysis-SQL
   ```

2. **Set Up the Database**: 
   - Create the database using the schema in `sql_query_p1.sql`
   - Import the CSV data file
   - Run data cleaning queries

3. **Run Analysis Queries**:
   - Start with basic queries in `sql_query_p1.sql` (Q.1-Q.18)
   - Explore advanced analytics in `advanced_analytics.sql`
   - Validate data quality using `data_quality_checks.sql`

4. **Review Insights**:
   - Read `insights.md` for key findings and recommendations
   - Use insights to inform business decisions

5. **Customize & Extend**:
   - Modify queries for your specific use cases
   - Add new analytical dimensions
   - Integrate with visualization tools (Tableau, Power BI, etc.)

## Technologies Used

- **Database**: PostgreSQL
- **Language**: SQL
- **Techniques**: Window Functions, CTEs, Aggregations, Subqueries, Statistical Analysis
- **Analysis Types**: Descriptive, Diagnostic, Predictive

## Skills Demonstrated

- ✅ Database design and setup
- ✅ Data cleaning and validation
- ✅ Exploratory data analysis
- ✅ Customer segmentation (RFM)
- ✅ Cohort analysis
- ✅ Revenue trend analysis
- ✅ Statistical outlier detection
- ✅ Business intelligence reporting
- ✅ Data quality assurance

## Author

This project is part of my data analytics portfolio, showcasing advanced SQL skills and analytical thinking essential for data analyst and business intelligence roles.

**Created by**: Data Analytics Portfolio  
**Last Updated**: February 2026  
**Project Type**: Retail Sales Analysis

If you have any questions, feedback, or would like to collaborate, feel free to reach out!

## License

This project is open source and available for educational purposes.

---

⭐ If you found this project helpful, please consider giving it a star!
