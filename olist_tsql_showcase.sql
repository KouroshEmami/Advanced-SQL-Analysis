/**************************************************************************************************
   📦 Olist Brazilian E-Commerce Dataset – Advanced T-SQL Portfolio Project
   Author: Kourosh Emami | Data Analyst

   🔍 Project Overview
   -------------------
   This project demonstrates advanced SQL Server capabilities using the Olist e-commerce dataset.
   The code showcases practical use of T-SQL for solving real-world data problems in a marketplace 
   setting, including behavior analysis, segmentation, and market-basket analytics.

   🧠 Key Concepts Demonstrated
   ----------------------------
   • Use of parameters and variables
   • Common Table Expressions (CTEs)
   • Window functions for segmentation and scoring
   • RFM (Recency, Frequency, Monetary) and CLV analysis
   • Cohort analysis and retention tracking
   • Market-basket analysis (co-purchased product categories)
   • Seller performance scoring
   • Dynamic ranking, percentiles, and BI-friendly views

   ⚙️ How to Use
   -------------
   1. Import raw CSV files from the Olist dataset into tables under the [dbo] schema.
   2. Run this script in SQL Server 2019+ or Azure SQL Database.
   3. Views will be created for direct use in BI tools like Power BI.

   📁 Source Dataset
   -----------------
   Olist Public Dataset – [https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce]

**************************************************************************************************/


USE [OlistDW];   -- change to your DB
SET NOCOUNT ON;
SET XACT_ABORT ON;

---------------------------------------------------------------
-- 0. Parameters
---------------------------------------------------------------
DECLARE @EndDate   date = ISNULL(
        (SELECT MAX(order_purchase_timestamp) FROM dbo.olist_orders_dataset),
        GETDATE());
DECLARE @StartDate date = DATEADD(year,-2,@EndDate);
DECLARE @TopN      int  = 20;

---------------------------------------------------------------
-- 1. Customer RFM & CLV
---------------------------------------------------------------
;WITH CustOrders AS (
    SELECT  o.customer_unique_id,
            DATEDIFF(day, MAX(o.order_purchase_timestamp), @EndDate) AS Recency,
            COUNT(DISTINCT o.order_id)                               AS Frequency,
            SUM(oi.price + oi.freight_value)                         AS Monetary
    FROM    dbo.olist_orders_dataset        o
    JOIN    dbo.olist_order_items_dataset   oi ON oi.order_id = o.order_id
    WHERE   o.order_purchase_timestamp BETWEEN @StartDate AND @EndDate
    GROUP BY o.customer_unique_id
), RFMScores AS (
    SELECT  *,
            NTILE(5) OVER (ORDER BY Recency DESC)  AS R_Score,
            NTILE(5) OVER (ORDER BY Frequency)     AS F_Score,
            NTILE(5) OVER (ORDER BY Monetary)      AS M_Score
    FROM    CustOrders
)
SELECT  customer_unique_id,
        Recency, Frequency, Monetary,
        R_Score, F_Score, M_Score,
        CONCAT(R_Score, F_Score, M_Score)               AS RFM_Cell,
        SUM(Monetary) OVER (ORDER BY Monetary DESC
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningRevenue
INTO    #CustomerRFM
FROM    RFMScores;

---------------------------------------------------------------
-- 2. Cohort Retention Matrix
---------------------------------------------------------------
;WITH Purchases AS (
    SELECT customer_unique_id,
           OrderMonth  = CAST(DATEFROMPARTS(YEAR(order_purchase_timestamp),
                                            MONTH(order_purchase_timestamp),1) AS date),
           CohortMonth = MIN(CAST(DATEFROMPARTS(YEAR(order_purchase_timestamp),
                                                MONTH(order_purchase_timestamp),1) AS date))
                         OVER (PARTITION BY customer_unique_id)
    FROM   dbo.olist_orders_dataset
), CohortStats AS (
    SELECT CohortMonth,
           DATEDIFF(month, CohortMonth, OrderMonth) AS MonthsSinceFirst,
           COUNT(DISTINCT customer_unique_id)       AS Customers
    FROM   Purchases
    GROUP  BY CohortMonth,
             DATEDIFF(month, CohortMonth, OrderMonth)
)
SELECT  CohortMonth,
        MonthsSinceFirst,
        Customers,
        100.0 * Customers /
        FIRST_VALUE(Customers) OVER (PARTITION BY CohortMonth ORDER BY MonthsSinceFirst) AS RetentionPct
INTO    #CohortRetention
FROM    CohortStats;

---------------------------------------------------------------
-- 3. Top‑N Products by Revenue
---------------------------------------------------------------
;WITH ProductRevenue AS (
    SELECT  p.product_id,
            p.product_category_name,
            SUM(oi.price)            AS Revenue,
            SUM(oi.freight_value)    AS Shipping,
            COUNT(*)                 AS ItemsSold
    FROM    dbo.olist_order_items_dataset  oi
    JOIN    dbo.olist_products_dataset     p  ON p.product_id = oi.product_id
    WHERE   EXISTS (SELECT 1
                    FROM   dbo.olist_orders_dataset o
                    WHERE  o.order_id = oi.order_id
                    AND    o.order_purchase_timestamp BETWEEN @StartDate AND @EndDate)
    GROUP BY p.product_id, p.product_category_name
)
SELECT  TOP (@TopN)
        product_id,
        product_category_name,
        Revenue,
        ItemsSold,
        Revenue / NULLIF(ItemsSold,0) AS AvgPrice
INTO    #TopProducts
FROM    ProductRevenue
ORDER   BY Revenue DESC;

---------------------------------------------------------------
-- 4. Market‑Basket Analysis (Category pairs)
---------------------------------------------------------------
;WITH DistinctCategories AS (
    SELECT DISTINCT
        o.order_id,
        p.product_category_name
    FROM dbo.olist_order_items_dataset oi
    JOIN dbo.olist_products_dataset p ON p.product_id = oi.product_id
    JOIN dbo.olist_orders_dataset o ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp BETWEEN @StartDate AND @EndDate
),
OrdersCategories AS (
    SELECT
        order_id,
        STRING_AGG(product_category_name, ',') AS Categories
    FROM DistinctCategories
    GROUP BY order_id
),
CategoryPairs AS (
    SELECT a.value AS CatA,
           b.value AS CatB
    FROM OrdersCategories
    CROSS APPLY STRING_SPLIT(Categories, ',') a
    CROSS APPLY STRING_SPLIT(Categories, ',') b
    WHERE a.value < b.value  -- avoid duplicates and self-pairs
)
SELECT CatA,
       CatB,
       COUNT(*) AS OrdersTogether
INTO #BasketPairs
FROM CategoryPairs
GROUP BY CatA, CatB
HAVING COUNT(*) >= 50
ORDER BY OrdersTogether DESC;

---------------------------------------------------------------
-- 5. Seller Performance Scorecard
---------------------------------------------------------------
;WITH SellerStats AS (
    SELECT  s.seller_id,
            COUNT(*)                             AS ItemsShipped,
            SUM(oi.price + oi.freight_value)     AS GrossRevenue,
            AVG(r.review_score)                  AS AvgReview,
            AVG(DATEDIFF(day,
                         o.order_purchase_timestamp,
                         o.order_delivered_customer_date)) AS AvgDeliveryDays
    FROM    dbo.olist_order_items_dataset  oi
    JOIN    dbo.olist_sellers_dataset      s  ON s.seller_id = oi.seller_id
    JOIN    dbo.olist_orders_dataset       o  ON o.order_id = oi.order_id
    JOIN    dbo.olist_order_reviews_dataset r ON r.order_id = o.order_id
    GROUP   BY s.seller_id
)
SELECT  seller_id,
        ItemsShipped,
        GrossRevenue,
        AvgReview,
        AvgDeliveryDays,
        PERCENT_RANK() OVER (ORDER BY GrossRevenue DESC) AS RevenuePercentile,
        PERCENT_RANK() OVER (ORDER BY AvgReview  DESC)   AS ReviewPercentile
INTO    #SellerScore
FROM    SellerStats;

---------------------------------------------------------------
-- 6. Publish as Views for BI consumption
---------------------------------------------------------------
IF OBJECT_ID('dbo.vwCustomerRFM','V') IS NOT NULL DROP VIEW dbo.vwCustomerRFM;
EXEC ('CREATE VIEW dbo.vwCustomerRFM AS SELECT * FROM #CustomerRFM');

IF OBJECT_ID('dbo.vwCohortRetention','V') IS NOT NULL DROP VIEW dbo.vwCohortRetention;
EXEC ('CREATE VIEW dbo.vwCohortRetention AS SELECT * FROM #CohortRetention');

IF OBJECT_ID('dbo.vwTopProducts','V') IS NOT NULL DROP VIEW dbo.vwTopProducts;
EXEC ('CREATE VIEW dbo.vwTopProducts AS SELECT * FROM #TopProducts');

IF OBJECT_ID('dbo.vwBasketPairs','V') IS NOT NULL DROP VIEW dbo.vwBasketPairs;
EXEC ('CREATE VIEW dbo.vwBasketPairs AS SELECT * FROM #BasketPairs');

IF OBJECT_ID('dbo.vwSellerScore','V') IS NOT NULL DROP VIEW dbo.vwSellerScore;
EXEC ('CREATE VIEW dbo.vwSellerScore AS SELECT * FROM #SellerScore');

PRINT 'Views created successfuly!';

---------------------------------------------------------------
-- 7. House‑keeping
---------------------------------------------------------------
DROP TABLE IF EXISTS #CustomerRFM, #CohortRetention,
                      #TopProducts, #BasketPairs, #SellerScore;
GO
