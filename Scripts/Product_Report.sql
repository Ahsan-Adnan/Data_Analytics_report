/*
===============================================================================
Product Report
===============================================================================
Purpose:
	- This report consolidates key product metrics and behaviors

Highlights:
	1.Gathers essential fields such as product name,category,subcategory and cost
	2.Segments products by revenue to identify High-performers,Mid-range, or 
	low-performers.
	3.Aggregatess product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)

	4. Calculates valueable KPIs:
		-recency (months since last sale)
		-average order revenue (AOR)
		-average monthly revenue
===============================================================================
*/
-- ============================================================================
-- Create Report:gold.report_products
-- ============================================================================

IF OBJECT_ID('gold.report_products','V') IS NOT NUll
	DROP VIEW gold.report_products;
GO
WITH base_query AS (
/* -----------------------------------------------------------------------------
1) Base Query : Retrieves core columns from tables
--------------------------------------------------------------------------------*/

SELECT 
f.order_number,
f.customer_key,
f.Order_Date,
f.Sales_amount,
f.Quantity,	
p.product_key,
p.product_name,
p.Category,
p.Subcategory,
p.cost
FROM gold.fact_sales f
RIGHT JOIN gold.dim_products p
ON f.product_key = p.product_key
WHERE Order_Date IS NOT NULL )

,Product_aggregation AS (

/* -----------------------------------------------------------------------------
2) Product Aggregations : Summarizes key metrics at the product level
--------------------------------------------------------------------------------*/

SELECT
product_key,
product_name,
Category,
subcategory,
cost,
COUNT(DISTINCT Order_Number) AS Total_Orders,
SUM (Sales_amount) AS Total_Sales,
SUM(Quantity) AS Total_quantity,
COUNT(DISTINCT Customer_key) AS total_customer,
MAX(order_date) AS last_sale_date,
DATEDIFF(month,MIN(order_date) ,MAX(order_date)) AS lifespan,
ROUND (AVG(CAST(sales_amount AS FLOAT) /NULLIF(quantity,0)),1) AS avg_selling_price
FROM base_query
GROUP BY
product_key,
product_name,
Category,
subcategory,
cost
)

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/

SELECT
product_key,
product_name,
Category,
subcategory,
cost,
lifespan,
last_sale_date,
DATEDIFF(month,last_sale_date,GETDATE()) AS recency_in_months,
CASE
	WHEN Total_Sales >50000 THEN 'High-Performer'
	WHEN Total_Sales >=10000 THEN 'Mid_Range'
	ELSE 'Low_Performer'
END AS product_segement,
Total_Orders,
total_sales,
Total_quantity,
total_customer,
avg_selling_price,
-- Average Order Revenue (AOR)
CASE 
	WHEN Total_Orders = 0 THEN 0
	ELSE Total_Sales /Total_Orders
END AS avg_order_revenue,
-- Average Monthly Revenue
CASE
	WHEN lifespan = 0 THEN total_sales
	ELSE total_sales /lifespan
END AS avg_monthly_revenue

FROM Product_aggregation


