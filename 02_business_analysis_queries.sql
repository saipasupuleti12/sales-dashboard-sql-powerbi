-- ============================================================================
-- E-Commerce Sales Data: Business Analysis Queries
-- Author: Sai Pasupuleti
-- Date: May 2026
-- Description: SQL queries to generate KPIs and insights for the 
--              Sales Performance Dashboard. These queries answer key 
--              business questions identified during stakeholder sessions.
-- ============================================================================


-- ============================================================================
-- KPI 1: REVENUE & PROFIT OVERVIEW
-- Business Question: "What is our overall sales performance?"
-- ============================================================================

SELECT 
    Order_Year,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Unique_Customers,
    ROUND(SUM(Total_Sales), 2) AS Total_Revenue,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(AVG(Total_Sales), 2) AS Avg_Order_Value,
    ROUND(SUM(Profit) / NULLIF(SUM(Total_Sales), 0) * 100, 1) AS Profit_Margin_Pct
FROM fact_sales
GROUP BY Order_Year
ORDER BY Order_Year;


-- ============================================================================
-- KPI 2: MONTHLY REVENUE TREND
-- Business Question: "How are sales trending month-over-month?"
-- ============================================================================

SELECT 
    Order_Year,
    Order_Month,
    COUNT(DISTINCT Order_ID) AS Orders,
    ROUND(SUM(Total_Sales), 2) AS Monthly_Revenue,
    ROUND(SUM(Profit), 2) AS Monthly_Profit,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Customer_Rating
FROM fact_sales
GROUP BY Order_Year, Order_Month
ORDER BY Order_Year, Order_Month;


-- ============================================================================
-- KPI 3: REVENUE BY REGION
-- Business Question: "Which regions are driving the most revenue?"
-- ============================================================================

SELECT 
    Region,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    ROUND(SUM(Total_Sales), 2) AS Total_Revenue,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Total_Sales), 0) * 100, 1) AS Profit_Margin_Pct,
    ROUND(AVG(Ship_Days), 1) AS Avg_Ship_Days,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating
FROM fact_sales
GROUP BY Region
ORDER BY Total_Revenue DESC;


-- ============================================================================
-- KPI 4: TOP PERFORMING CATEGORIES & PRODUCTS
-- Business Question: "Which product categories are most profitable?"
-- ============================================================================

-- By Category
SELECT 
    Category,
    COUNT(DISTINCT Order_ID) AS Orders,
    SUM(Quantity) AS Units_Sold,
    ROUND(SUM(Total_Sales), 2) AS Revenue,
    ROUND(SUM(Profit), 2) AS Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Total_Sales), 0) * 100, 1) AS Margin_Pct,
    ROUND(SUM(Total_Sales) * 100.0 / SUM(SUM(Total_Sales)) OVER(), 1) AS Revenue_Share_Pct
FROM fact_sales
GROUP BY Category
ORDER BY Revenue DESC;


-- Top 10 Products by Revenue
SELECT 
    Product_Name,
    Category,
    Sub_Category,
    COUNT(DISTINCT Order_ID) AS Times_Ordered,
    SUM(Quantity) AS Units_Sold,
    ROUND(SUM(Total_Sales), 2) AS Revenue,
    ROUND(SUM(Profit), 2) AS Profit
FROM fact_sales
GROUP BY Product_Name, Category, Sub_Category
ORDER BY Revenue DESC
LIMIT 10;


-- ============================================================================
-- KPI 5: SALES CHANNEL PERFORMANCE
-- Business Question: "How do our sales channels compare?"
-- ============================================================================

SELECT 
    Sales_Channel,
    COUNT(DISTINCT Order_ID) AS Orders,
    ROUND(SUM(Total_Sales), 2) AS Revenue,
    ROUND(SUM(Profit), 2) AS Profit,
    ROUND(AVG(Total_Sales), 2) AS Avg_Order_Value,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating,
    ROUND(SUM(CASE WHEN Returned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Return_Rate_Pct
FROM fact_sales
GROUP BY Sales_Channel
ORDER BY Revenue DESC;


-- ============================================================================
-- KPI 6: CUSTOMER SEGMENT ANALYSIS
-- Business Question: "Which customer segments are most valuable?"
-- ============================================================================

SELECT 
    Customer_Segment,
    COUNT(DISTINCT Customer_ID) AS Unique_Customers,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    ROUND(SUM(Total_Sales), 2) AS Revenue,
    ROUND(SUM(Profit), 2) AS Profit,
    ROUND(SUM(Total_Sales) / COUNT(DISTINCT Customer_ID), 2) AS Revenue_Per_Customer,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Satisfaction
FROM fact_sales
GROUP BY Customer_Segment
ORDER BY Revenue DESC;


-- ============================================================================
-- KPI 7: DISCOUNT IMPACT ANALYSIS
-- Business Question: "Are discounts actually improving profitability?"
-- ============================================================================

SELECT 
    Discount_Tier,
    COUNT(DISTINCT Order_ID) AS Orders,
    ROUND(SUM(Total_Sales), 2) AS Revenue,
    ROUND(SUM(Profit), 2) AS Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Total_Sales), 0) * 100, 1) AS Margin_Pct,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating,
    ROUND(SUM(CASE WHEN Returned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Return_Rate_Pct
FROM fact_sales
GROUP BY Discount_Tier
ORDER BY 
    CASE Discount_Tier 
        WHEN 'No Discount' THEN 1 
        WHEN 'Low (1-10%)' THEN 2 
        WHEN 'Medium (11-20%)' THEN 3 
        WHEN 'High (21%+)' THEN 4 
    END;


-- ============================================================================
-- KPI 8: SHIPPING & FULFILLMENT PERFORMANCE
-- Business Question: "How does shipping speed affect customer satisfaction?"
-- ============================================================================

SELECT 
    Shipping_Speed,
    COUNT(DISTINCT Order_ID) AS Orders,
    ROUND(AVG(Ship_Days), 1) AS Avg_Days,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating,
    ROUND(SUM(CASE WHEN Returned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Return_Rate_Pct,
    ROUND(AVG(Shipping_Cost), 2) AS Avg_Ship_Cost
FROM fact_sales
GROUP BY Shipping_Speed
ORDER BY Avg_Days;


-- ============================================================================
-- KPI 9: RETURN RATE ANALYSIS
-- Business Question: "What's driving product returns?"
-- ============================================================================

-- Returns by category
SELECT 
    Category,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN Returned = 'Yes' THEN 1 ELSE 0 END) AS Returned_Orders,
    ROUND(SUM(CASE WHEN Returned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Return_Rate_Pct,
    ROUND(SUM(CASE WHEN Returned = 'Yes' THEN Total_Sales ELSE 0 END), 2) AS Revenue_At_Risk
FROM fact_sales
GROUP BY Category
ORDER BY Return_Rate_Pct DESC;


-- Returns correlation with satisfaction
SELECT 
    Satisfaction_Level,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN Returned = 'Yes' THEN 1 ELSE 0 END) AS Returns,
    ROUND(SUM(CASE WHEN Returned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Return_Rate_Pct
FROM fact_sales
GROUP BY Satisfaction_Level
ORDER BY Return_Rate_Pct DESC;


-- ============================================================================
-- KPI 10: YoY GROWTH ANALYSIS
-- Business Question: "How does 2024 compare to 2023?"
-- ============================================================================

WITH yearly AS (
    SELECT 
        Order_Year,
        Order_Quarter,
        ROUND(SUM(Total_Sales), 2) AS Revenue,
        ROUND(SUM(Profit), 2) AS Profit,
        COUNT(DISTINCT Order_ID) AS Orders
    FROM fact_sales
    GROUP BY Order_Year, Order_Quarter
)
SELECT 
    y2.Order_Quarter AS Quarter,
    y1.Revenue AS Revenue_2023,
    y2.Revenue AS Revenue_2024,
    ROUND((y2.Revenue - y1.Revenue) / NULLIF(y1.Revenue, 0) * 100, 1) AS Revenue_Growth_Pct,
    y1.Orders AS Orders_2023,
    y2.Orders AS Orders_2024
FROM yearly y1
JOIN yearly y2 
    ON y1.Order_Quarter = y2.Order_Quarter
WHERE y1.Order_Year = 2023 
  AND y2.Order_Year = 2024
ORDER BY Quarter;
