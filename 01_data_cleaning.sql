-- ============================================================================
-- E-Commerce Sales Data: Cleaning & Preparation
-- Author: Sai Pasupuleti
-- Date: May 2026
-- Description: SQL script to clean, validate, and prepare raw e-commerce 
--              sales data for Power BI dashboard visualization.
-- Database: PostgreSQL / SQL Server (compatible with both)
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE STAGING TABLE & LOAD RAW DATA
-- ============================================================================

CREATE TABLE IF NOT EXISTS stg_ecommerce_sales (
    Order_ID            VARCHAR(20),
    Order_Date          DATE,
    Ship_Date           DATE,
    Ship_Days           INT,
    Customer_ID         VARCHAR(20),
    Customer_Segment    VARCHAR(50),
    Region              VARCHAR(50),
    State               VARCHAR(50),
    Category            VARCHAR(50),
    Sub_Category        VARCHAR(50),
    Product_Name        VARCHAR(100),
    Unit_Price          DECIMAL(10,2),
    Quantity            INT,
    Discount_Pct        INT,
    Discount_Amount     DECIMAL(10,2),
    Shipping_Cost       DECIMAL(10,2),
    Total_Sales         DECIMAL(10,2),
    Cost_Per_Unit       DECIMAL(10,2),
    Profit              DECIMAL(10,2),
    Sales_Channel       VARCHAR(50),
    Payment_Method      VARCHAR(50),
    Customer_Rating     INT,
    Returned            INT
);

-- Note: Load CSV using COPY (PostgreSQL) or BULK INSERT (SQL Server)
-- COPY stg_ecommerce_sales FROM '/path/to/ecommerce_sales_2023_2024.csv' 
--   DELIMITER ',' CSV HEADER;


-- ============================================================================
-- STEP 2: DATA QUALITY CHECKS
-- ============================================================================

-- Check for NULL values in critical columns
SELECT 
    'Order_ID' AS Column_Name, COUNT(*) AS Null_Count 
FROM stg_ecommerce_sales WHERE Order_ID IS NULL
UNION ALL
SELECT 'Order_Date', COUNT(*) FROM stg_ecommerce_sales WHERE Order_Date IS NULL
UNION ALL
SELECT 'Customer_ID', COUNT(*) FROM stg_ecommerce_sales WHERE Customer_ID IS NULL
UNION ALL
SELECT 'Total_Sales', COUNT(*) FROM stg_ecommerce_sales WHERE Total_Sales IS NULL
UNION ALL
SELECT 'Profit', COUNT(*) FROM stg_ecommerce_sales WHERE Profit IS NULL;


-- Check for duplicate Order IDs
SELECT 
    Order_ID, 
    COUNT(*) AS Duplicate_Count
FROM stg_ecommerce_sales
GROUP BY Order_ID
HAVING COUNT(*) > 1;


-- Validate date ranges — ensure no future dates or impossible ship dates
SELECT 
    COUNT(*) AS Invalid_Ship_Dates
FROM stg_ecommerce_sales
WHERE Ship_Date < Order_Date;


-- Validate that Total_Sales = (Unit_Price * Quantity) - Discount_Amount
SELECT 
    Order_ID,
    Unit_Price,
    Quantity,
    Discount_Amount,
    Total_Sales,
    ROUND((Unit_Price * Quantity) - Discount_Amount, 2) AS Calculated_Sales,
    ROUND(Total_Sales - ((Unit_Price * Quantity) - Discount_Amount), 2) AS Variance
FROM stg_ecommerce_sales
WHERE ABS(Total_Sales - ((Unit_Price * Quantity) - Discount_Amount)) > 0.01;


-- Check value distributions for key dimensions
SELECT Region, COUNT(*) AS Order_Count, 
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM stg_ecommerce_sales), 1) AS Pct
FROM stg_ecommerce_sales
GROUP BY Region
ORDER BY Order_Count DESC;


-- ============================================================================
-- STEP 3: CREATE CLEAN PRODUCTION TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS fact_sales AS
SELECT 
    Order_ID,
    Order_Date,
    Ship_Date,
    Ship_Days,
    Customer_ID,
    Customer_Segment,
    Region,
    State,
    Category,
    Sub_Category,
    Product_Name,
    Unit_Price,
    Quantity,
    Discount_Pct,
    Discount_Amount,
    Shipping_Cost,
    Total_Sales,
    Cost_Per_Unit,
    Profit,
    Sales_Channel,
    Payment_Method,
    Customer_Rating,
    CASE WHEN Returned = 1 THEN 'Yes' ELSE 'No' END AS Returned,
    
    -- Derived columns for Power BI
    EXTRACT(YEAR FROM Order_Date) AS Order_Year,
    EXTRACT(MONTH FROM Order_Date) AS Order_Month,
    EXTRACT(QUARTER FROM Order_Date) AS Order_Quarter,
    
    CASE 
        WHEN Discount_Pct = 0 THEN 'No Discount'
        WHEN Discount_Pct BETWEEN 1 AND 10 THEN 'Low (1-10%)'
        WHEN Discount_Pct BETWEEN 11 AND 20 THEN 'Medium (11-20%)'
        ELSE 'High (21%+)'
    END AS Discount_Tier,
    
    CASE 
        WHEN Ship_Days <= 2 THEN 'Fast (1-2 days)'
        WHEN Ship_Days BETWEEN 3 AND 5 THEN 'Standard (3-5 days)'
        ELSE 'Slow (6+ days)'
    END AS Shipping_Speed,
    
    CASE 
        WHEN Customer_Rating >= 4 THEN 'Satisfied'
        WHEN Customer_Rating = 3 THEN 'Neutral'
        ELSE 'Dissatisfied'
    END AS Satisfaction_Level,
    
    ROUND(Profit / NULLIF(Total_Sales, 0) * 100, 1) AS Profit_Margin_Pct

FROM stg_ecommerce_sales
WHERE Order_ID IS NOT NULL 
  AND Total_Sales > 0;


-- ============================================================================
-- STEP 4: CREATE DIMENSION TABLES FOR STAR SCHEMA (Power BI)
-- ============================================================================

-- Date dimension
CREATE TABLE IF NOT EXISTS dim_date AS
SELECT DISTINCT
    Order_Date AS Date_Key,
    EXTRACT(YEAR FROM Order_Date) AS Year,
    EXTRACT(QUARTER FROM Order_Date) AS Quarter,
    EXTRACT(MONTH FROM Order_Date) AS Month_Num,
    TO_CHAR(Order_Date, 'Month') AS Month_Name,
    TO_CHAR(Order_Date, 'Mon') AS Month_Short,
    EXTRACT(DOW FROM Order_Date) AS Day_Of_Week,
    TO_CHAR(Order_Date, 'Day') AS Day_Name,
    CASE WHEN EXTRACT(MONTH FROM Order_Date) <= 6 THEN 'H1' ELSE 'H2' END AS Half_Year
FROM stg_ecommerce_sales
ORDER BY Order_Date;


-- Product dimension
CREATE TABLE IF NOT EXISTS dim_product AS
SELECT DISTINCT
    Product_Name,
    Sub_Category,
    Category,
    ROUND(AVG(Unit_Price), 2) AS Avg_Unit_Price
FROM stg_ecommerce_sales
GROUP BY Product_Name, Sub_Category, Category
ORDER BY Category, Sub_Category, Product_Name;


-- Customer dimension
CREATE TABLE IF NOT EXISTS dim_customer AS
SELECT DISTINCT
    Customer_ID,
    Customer_Segment,
    Region,
    State
FROM stg_ecommerce_sales;


SELECT 'Data cleaning complete. Production tables created.' AS Status;
