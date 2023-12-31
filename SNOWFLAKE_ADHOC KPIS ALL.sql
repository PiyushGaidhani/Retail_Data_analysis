USE RETAIL;
SELECT * FROM demographic_RAW;
SELECT * FROM CAMPAIGN_DESC_RAW;
SELECT * FROM CAMPAIGN_RAW;
SELECT * FROM PRODUCT_RAW;
SELECT * FROM COUPON_RAW;
SELECT * FROM COUPON_REDEMPT_RAW;
SELECT * FROM TRANSACTION_RAW;


select * from CAMPAIGN_DESC_NEW;

select * from COUPON_REDEMPT_NEW;

select * from TRANSACTION_NEW;

-----department wise product count
SELECT DISTINCT(DEPARTMENT),COUNT(*) AS TOTAL_PRODUCT 
FROM PRODUCT_RAW
GROUP BY 1
ORDER BY 2 DESC;


/*1.	Customer Demographics KPIs:
A. Count of unique households: Measure the total number of unique households in the Demographic table.
B. Household composition distribution: Analyze the distribution of household compositions (HH_COMP_DESC) to understand the composition of households.
C.	Age distribution: Calculate the percentage or count of customers in different age groups (AGE_DESC).
D.	Marital status distribution: Analyze the proportion of customers in different marital status categories (MARITAL_STATUS_CODE).
E.	Income distribution: Determine the distribution of customers across income levels (INCOME_DESC).
F. Homeownership distribution: Calculate the percentage or count of customers who own or rent their homes (HOMEOWNER_DESC).*/

SELECT COUNT(DISTINCT HOUSEHOLD_KEY) AS TOTAL_HOUSEHOLDS FROM DEMOGRAPHIC_RAW; --2,500

SELECT HH_COMP_DESC,COUNT(DISTINCT HOUSEHOLD_KEY) AS TOTAL_HOUSEHOLDS 
FROM DEMOGRAPHIC_RAW
GROUP BY 1
ORDER BY 2 DESC;


SELECT AGE_DESC,TOTAL_HOUSEHOLDS,ROUND(TOTAL_HOUSEHOLDS/2500 * 100,2) AS PERC_AGEWISE_HOUSEHOLDS_DISTR
FROM
(SELECT AGE_DESC,
COUNT(DISTINCT HOUSEHOLD_KEY) AS TOTAL_HOUSEHOLDS
FROM demographic_RAW 
GROUP BY 1
ORDER BY 2 DESC)
GROUP BY 1,2;

SELECT MARITAL_STATUS_CODE , 
COUNT(DISTINCT HOUSEHOLD_KEY) AS TOTAL_HOUSEHOLDS,
ROUND(COUNT(DISTINCT HOUSEHOLD_KEY) / 2500 * 100 , 2) AS PERC_MARITAL_HOUSEHOLDS_DISTR
FROM demographic_RAW
GROUP BY 1
ORDER BY 2 DESC;

SELECT INCOME_DESC , 
COUNT(DISTINCT HOUSEHOLD_KEY) AS TOTAL_HOUSEHOLDS,
ROUND(COUNT(DISTINCT HOUSEHOLD_KEY) / 2500 * 100 , 2) AS PERC_INCOME_HOUSEHOLDS_DISTR
FROM demographic_RAW
GROUP BY 1
ORDER BY 2 DESC;

SELECT HOMEOWNER_DESC , 
COUNT(DISTINCT HOUSEHOLD_KEY) AS TOTAL_HOUSEHOLDS,
ROUND(COUNT(DISTINCT HOUSEHOLD_KEY) / 2500 * 100 , 2) AS PERC_HOMEOWNER_DESC_DISTR
FROM demographic_RAW
GROUP BY 1
ORDER BY 2 DESC;



SELECT T.HOUSEHOLD_KEY,D.AGE_DESC,D.MARITAL_STATUS_CODE,D.INCOME_DESC,AVG(T.SALES_VALUE)AS AVG_AMOUNT,
AVG(T.RETAIL_DISC)AS AVG_RETAIL_DIS,AVG(T.COUPON_DISC)AS AVG_COUPON_DISC,AVG(T.COUPON_MATCH_DISC)AS AVG_COUP_MATCH_DISC
FROM TRANSACTION_NEW T
LEFT OUTER JOIN demographic_RAW D ON T.HOUSEHOLD_KEY =D.HOUSEHOLD_KEY
GROUP BY 1,2,3,4
ORDER BY 1;

CREATE OR REPLACE PROCEDURE Household_kpi()
RETURNS STRING
LANGUAGE SQL
AS
$$
 CREATE OR REPLACE TABLE Household_kpi AS (SELECT T.HOUSEHOLD_KEY,D.AGE_DESC,D.MARITAL_STATUS_CODE,D.INCOME_DESC,AVG(T.SALES_VALUE)AS AVG_AMOUNT,
AVG(T.RETAIL_DISC)AS AVG_RETAIL_DIS,AVG(T.COUPON_DISC)AS AVG_COUPON_DISC,AVG(T.COUPON_MATCH_DISC)AS AVG_COUP_MATCH_DISC
FROM TRANSACTION_NEW T
LEFT OUTER JOIN demographic_RAW D ON T.HOUSEHOLD_KEY =D.HOUSEHOLD_KEY
GROUP BY 1,2,3,4
ORDER BY 1);
$$;

SHOW PROCEDURES;

//Campaign KPIs:
//o Number of campaigns: Count the total number of campaigns in the Campaign
//table.
//o Campaign duration: Calculate the duration of each campaign by subtracting the
//start day from the end day (in the Campaign_desc table).
//o Campaign effectiveness: Analyze the number of households associated with each
//campaign (in the Campaign table) to measure campaign reach.//

SELECT COUNT(DISTINCT CAMPAIGN) AS TOTAL_CAMPAIGN FROM RETAIL.PUBLIC.CAMPAIGN_DESC_NEW;

//SELECT * FROM CAMPAIGN_DESC_NEW;
//SELECT CAMPAIGN, START_DATE, END_DATE//
CREATE OR REPLACE PROCEDURE CAMPAIGN_KPI()
RETURNS STRING
LANGUAGE SQL
AS
$$
CREATE OR REPLACE TABLE CAMPAIGN_KPI AS 
SELECT A.CAMPAIGN,A.CAMPAIGN_DURATION,START_DATE,END_DATE,A.DESCRIPTION,START_YEAR,END_YEAR,
COUNT( B.CAMPAIGN) AS TOTAL_CAMPAIGN,ROUND(COUNT(DISTINCT HOUSEHOLD_KEY)/2500*100,2) AS PER_DIS_CAMPAIGN
FROM RETAIL.PUBLIC.CAMPAIGN_DESC_NEW A LEFT JOIN CAMPAIGN_RAW B ON A.CAMPAIGN=B.CAMPAIGN
GROUP BY 1,2,3,4,5,6,7;
$$;

SELECT * FROM CAMPAIGN_KPI;
/*Coupon KPIs:
o Coupon redemption rate: Calculate the percentage of coupons redeemed (from the
coupon_redempt table) compared to the total number of coupons distributed (from
the Coupon table).
o Coupon usage by campaign: Measure the number of coupon redemptions (from
the coupon_redempt table) for each campaign (in the Coupon table).*/

SELECT CAMPAIGN,COUNT(DISTINCT COUPON_UPC) AS TOTAL_DISTRIBUTED_COUPON FROM COUPON_RAW
GROUP BY 1;

SELECT COUNT( DISTINCT COUPON_UPC) AS REDEM_COUPON FROM RETAIL.PUBLIC.COUPON_REDEMPT_NEW;

CREATE OR REPLACE PROCEDURE COUPON_KPI()
RETURNS STRING
LANGUAGE SQL
AS
$$
CREATE OR REPLACE TABLE COUPON_KPI AS 
SELECT CAMPAIGN,REDEM_COUPON,ROUND(REDEM_COUPON/TOTAL_DISTRIBUTED_COUPON*100,2)  PER_REDMM  FROM 
(SELECT  A.CAMPAIGN,COUNT(DISTINCT A.COUPON_UPC) AS TOTAL_DISTRIBUTED_COUPON,COUNT( DISTINCT B.COUPON_UPC) AS REDEM_COUPON 
FROM COUPON_RAW A LEFT JOIN RETAIL.PUBLIC.COUPON_REDEMPT_NEW B ON A.CAMPAIGN=B.CAMPAIGN
GROUP BY 1
);
$$;

SELECT * FROM COUPON_KPI;


/*Product KPIs:
o Sales value: Calculate the total sales value for each product (in the
Transaction_data table) to identify top-selling products.
o Manufacturer distribution: Analyze the distribution of products across different
manufacturers (in the Product table).
o Department-wise sales: Measure the sales value by department (in the Product
table) to understand which departments contribute most to revenue.
o Brand-wise sales: Calculate the sales value for each brand (in the Product table) to
identify top-selling brands.*/

SELECT* FROM RETAIL.PUBLIC.TRANSACTION_NEW;
SELECT* FROM PRODUCT_RAW;

SELECT DISTINCT PRODUCT_ID AS DISTINCT_PRODUCT,SUM(SALES_VALUE)AS TOTAL_SALES FROM RETAIL.PUBLIC.TRANSACTION_NEW
GROUP BY 1
ORDER BY 2 DESC ;

SELECT MANUFACTURER,COUNT(*) AS PRODUCT_COUNT FROM PRODUCT_RAW
GROUP BY 1;

SELECT DEPARTMENT,SUM(SALES_VALUE) AS TOTAL_SALES FROM RETAIL.PUBLIC.TRANSACTION_NEW A INNER JOIN 
PRODUCT_RAW B ON A.PRODUCT_ID=B.PRODUCT_ID
GROUP BY 1
ORDER BY 2 DESC;

SELECT BRAND ,SUM(SALES_VALUE) AS TOTAL_SALES FROM RETAIL.PUBLIC.TRANSACTION_NEW A
INNER JOIN PRODUCT_RAW B ON A.PRODUCT_ID=B.PRODUCT_ID
GROUP BY 1
ORDER BY 2 DESC;

CREATE OR REPLACE PROCEDURE PRODUCT_KPI()
RETURNS STRING
LANGUAGE SQL
AS
$$
CREATE OR REPLACE TABLE PRODUCT_KPI AS 
SELECT A.PRODUCT_ID,DEPARTMENT,BRAND,MANUFACTURER,SUM(SALES_VALUE)AS TOTAL_SALES,COUNT(B.PRODUCT_ID) AS PRODUCT_COUNT FROM RETAIL.PUBLIC.TRANSACTION_NEW A LEFT JOIN PRODUCT_RAW B ON A.PRODUCT_ID=B.PRODUCT_ID
GROUP BY 1,2,3,4
ORDER BY 5 DESC;
$$;

SELECT *FROM PRODUCT_KPI;

/*Transaction KPIs:
o Total sales value: Calculate the sum of sales values (in the Transaction_data table)
to measure overall revenue.
o Average transaction value: Calculate the average sales value per transaction to
understand customer spending patterns.
o Quantity sold: Measure the total quantity sold (in the Transaction_data table) to
understand product demand.
o Discounts: Analyze the amount and impact of discounts (RETAIL_DISC,
COUPON_DISC, COUPON_MATCH_DISC) on sales value.*/

SELECT* FROM RETAIL.PUBLIC.TRANSACTION_NEW;
SELECT (QUANTITY*SALES_VALUE) AS TOTAL_REVENUE, SUM(SALES_VALUE) AS TOTAL_SALES FROM RETAIL.PUBLIC.TRANSACTION_NEW
GROUP BY 1;

SELECT PRODUCT_ID,AVG(SALES_VALUE) AS AVG_SALE_PER_TRNX FROM RETAIL.PUBLIC.TRANSACTION_NEW
GROUP BY 1;

SELECT PRODUCT_ID,SUM(QUANTITY)AS TOTAL_QTY FROM RETAIL.PUBLIC.TRANSACTION_NEW
GROUP BY 1;

SELECT 
    SUM(RETAIL_DISC) AS total_retail_discount,
    SUM(COUPON_DISC) AS total_coupon_discount,
    SUM(COUPON_MATCH_DISC) AS total_coupon_match_discount,
    SUM(RETAIL_DISC + COUPON_DISC + COUPON_MATCH_DISC) AS total_discount_amount,
    SUM(sales_value) AS total_sales_value,
    (SUM(RETAIL_DISC + COUPON_DISC + COUPON_MATCH_DISC) / SUM(sales_value)) * 100 AS discount_impact_percentage
FROM
    RETAIL.PUBLIC.TRANSACTION_NEW
    
    ;
CREATE OR REPLACE PROCEDURE TRANSACTION_KPI()
RETURNS STRING
LANGUAGE SQL
AS
 $$   
CREATE OR REPLACE TABLE TRANSACTION_KPI AS 
SELECT PRODUCT_ID,DATE,(QUANTITY*SALES_VALUE) AS TOTAL_REVENUE,SUM(SALES_VALUE) AS TOTAL_SALES ,AVG(SALES_VALUE) AS AVG_SALE_PER_TRNX ,SUM(QUANTITY)AS TOTAL_QTY,SUM(COUPON_DISC) AS total_coupon_discount, 
SUM(COUPON_MATCH_DISC) AS total_coupon_match_discount,SUM(RETAIL_DISC + COUPON_DISC + COUPON_MATCH_DISC) AS total_discount_amount FROM RETAIL.PUBLIC.TRANSACTION_NEW
GROUP BY 1,2,3;
$$;

SELECT * FROM TRANSACTION_KPI;













SHOW PROCEDURES;


CALL Household_kpi();
CALL CAMPAIGN_KPI();
CALL COUPON_KPI();
CALL PRODUCT_KPI();
CALL TRANSACTION_KPI();


CREATE OR REPLACE TASK  Household_kpi_TASK
WAREHOUSE = COMPUTE_WH
SCHEDULE = '5 MINUTE' 
AS CALL Household_kpi();


CREATE OR REPLACE TASK  CAMPAIGN_KPI_TASK
WAREHOUSE = COMPUTE_WH
SCHEDULE = '5 MINUTE' 
AS CALL CAMPAIGN_KPI();

CREATE OR REPLACE TASK  COUPON_KPI_TASK
WAREHOUSE = COMPUTE_WH
SCHEDULE = '5 MINUTE' 
AS CALL COUPON_KPI();

CREATE OR REPLACE TASK  PRODUCT_KPI_TASK
WAREHOUSE = COMPUTE_WH
SCHEDULE = '5 MINUTE' 
AS CALL PRODUCT_KPI();

CREATE OR REPLACE TASK  TRANSACTION_KPI_TASK
WAREHOUSE = COMPUTE_WH
SCHEDULE = '5 MINUTE' 
AS CALL TRANSACTION_KPI();

SHOW TASKS;

ALTER TASK   Household_kpi_TASK RESUME;
ALTER TASK  Household_kpi_TASK SUSPEND; 
