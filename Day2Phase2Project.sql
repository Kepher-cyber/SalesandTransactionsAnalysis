SELECT *
FROM dataanalytics.customer_info;

SELECT *
FROM dataanalytics.sales_transactions;

--1. Find the total number of transactions per city
SELECT ci.city ,COUNT(st.transaction_id) AS "Total Transactions" 
FROM dataanalytics.sales_transactions st
LEFT JOIN dataanalytics.customer_info ci  
ON ci.customer_id = st.customer_id
GROUP BY ci.city
ORDER BY COUNT(st.transaction_id) DESC ;

--2. Retrieve the top 5 most purchased products based on total quantity sold
SELECT product_name,category,quantity,COUNT(product_name)
FROM dataanalytics.sales_transactions st 
GROUP BY product_name, category,quantity
ORDER BY COUNT(*) DESC;

SELECT  product_name, SUM(quantity) AS "Product Quantity"
FROM dataanalytics.sales_transactions st 
GROUP BY product_name 
ORDER BY "Product Quantity" DESC;

-- 3.Find the average transaction amount per category.
SELECT  category, AVG(total_amount)::numeric(20,2) AS "Average Transaction Amount"
FROM dataanalytics.sales_transactions st 
GROUP BY category 
ORDER BY "Average Transaction Amount";

-- 4.Identify the payment method that has the highest total sales.
SELECT payment_method, SUM(total_amount) AS "Total_Sales"
FROM dataanalytics.sales_transactions st 
GROUP BY payment_method 
ORDER BY "Total_Sales" 

-- 5.Find customers who have made at least 5 transactions
SELECT customer_id, COUNT(transaction_id) AS "Num_of_Transactions"
FROM dataanalytics.sales_transactions st 
GROUP BY customer_id
HAVING COUNT(transaction_id) >= 5;

select first_name,last_name ,count(transaction_id) as transaction_count
from sales_transactions
join customer_info on customer_info.customer_id = sales_transactions.customer_id 
group by first_name,last_name
having count(transaction_id) >=5;

-- 6.Retrieve all customers who registered in the last 6 months but have not made any transactions.



select first_name,last_name,transaction_id
from sales_transactions 
left join customer_info 
on customer_info.customer_id = sales_transactions.customer_id
where registration_date >= current_date - make_interval(months => 6)
and transaction_id is null;

-- 7.Find the total revenue generated in each year from sales transactions
SELECT SUM(total_amount) AS "Total_Revenue", EXTRACT(YEAR FROM transaction_date) AS "Sales_Year"
FROM dataanalytics.sales_transactions st 
GROUP BY "Sales_Year"
ORDER BY "Sales_Year" DESC;

--8.List the number of unique products sold in each category.
SELECT DISTINCT COUNT(product_name) AS "Unique_Products",category
FROM dataanalytics.sales_transactions st 
GROUP BY category, product_name 
ORDER BY "Unique_Products" DESC ;

--9.Find all customers who have made purchases across at least 3 different product categories
SELECT ci.customer_id, ci.first_name, COUNT(DISTINCT(st.category)) AS category_count
FROM dataanalytics.customer_info ci 
JOIN dataanalytics.sales_transactions st 
ON ci.customer_id = st.customer_id 
GROUP BY ci.customer_id
HAVING COUNT(DISTINCT(st.category)) >=3
ORDER BY category_count DESC;

--10.Identify the most popular purchase day of the week based on transaction count.
SELECT EXTRACT(DAY FROM transaction_date) AS "Day_of_Week", COUNT(transaction_id) AS "Transaction_Count"
FROM dataanalytics.sales_transactions st 
GROUP BY "Day_of_Week"
ORDER BY "Transaction_Count" DESC ;

SELECT TO_CHAR(transaction_date, 'day') as "Day_of_the_Week" , COUNT(transaction_id) as "Transaction_Count"
FROM dataanalytics.sales_transactions
GROUP BY "Day_of_the_Week"
ORDER BY "Transaction_Count" DESC;

--11.Find the top 3 customers who have spent the most in the last 12 months.
SELECT ci.customer_id, SUM(total_amount) AS "Total_Spend"
FROM dataanalytics.customer_info ci 
JOIN dataanalytics.sales_transactions st 
ON ci.customer_id = st.customer_id
WHERE st.transaction_date <= CURRENT_DATE - INTERVAL '12 months'
GROUP BY ci.customer_id
ORDER BY "Total_Spend" DESC;

--12.Determine the percentage of total revenue contributed by each product category.
SELECT category, SUM(st.total_amount)  AS "Total_Revenue"
FROM dataanalytics.sales_transactions st 
GROUP BY category 
ORDER BY "Total_Revenue" DESC 

select category,
      sum(total_amount) as categoty_revenue,
      Round(SUM(total_amount) * 100.0 / (SELECT SUM(total_amount) FROM project_phase_two.sales_transactions),2) as revenue_percentage
from project_phase_two.sales_transactions
group by category
order by revenue_percentage desc;

--13.Find the month-over-month sales growth for the last 12 months.
-- Efficient Method 1
WITH monthly_sales AS (
    SELECT 
        TO_CHAR(transaction_date, 'MONTH') AS sales_month,  -- Format month with year for ordering
        SUM(total_amount) AS total_monthly_sales
    FROM dataanalytics.sales_transactions
    WHERE transaction_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY sales_month
)
SELECT 
    sales_month,
    total_monthly_sales,
    total_monthly_sales - LAG(total_monthly_sales) OVER(ORDER BY sales_month) AS sales_difference,
    (total_monthly_sales - LAG(total_monthly_sales) OVER(ORDER BY sales_month)) / 
    NULLIF(LAG(total_monthly_sales) OVER(ORDER BY sales_month), 0) AS sales_growth_rate
FROM monthly_sales
ORDER BY sales_month DESC;

-- Efficient Method 2
SELECT 
	*,
	ROUND(("Current_Month_Sales" - "Previous_Month_Sales")/ "Previous_Month_Sales" * 100,2)  AS "%Percentage_Change"
FROM (
	SELECT 
	EXTRACT(MONTH FROM transaction_date) AS "Month_Name",
	SUM(total_amount) AS "Current_Month_Sales",
	LAG(SUM(total_amount)) OVER(ORDER BY EXTRACT(MONTH FROM transaction_date)) AS "Previous_Month_Sales"
FROM dataanalytics.sales_transactions
WHERE transaction_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY "Month_Name"
);

--14.Identify customers who have increased their spending by at least 30% compared to the previous year.
SELECT
	*,
	"Total_Sales" - "Previous_Year"AS "Change",
	(("Total_Sales" - "Previous_Year")* 100)/"Total_Sales"AS "%Change"
FROM (
	SELECT
	customer_id,
	EXTRACT(YEAR FROM transaction_date) AS "Year",
	SUM(total_amount) AS "Total_Sales",
	LAG(SUM(total_amount)) OVER(PARTITION BY customer_id ORDER BY EXTRACT(YEAR FROM transaction_date)) AS "Previous_Year"
FROM dataanalytics.sales_transactions st
GROUP BY customer_id, "Year"
);

--15.Find the first purchase date for each customer.
SELECT 
	customer_id,
	MIN(transaction_date) AS "First_Purchase_Date"
FROM dataanalytics.sales_transactions
GROUP BY customer_id 




