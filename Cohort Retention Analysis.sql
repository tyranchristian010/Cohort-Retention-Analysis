--Overview of the the online_retail table
SELECT 
	   [InvoiceNo]
      ,[StockCode]
      ,[Description]
      ,[Quantity]
      ,[InvoiceDate]
      ,[UnitPrice]
      ,[CustomerID]
      ,[Country]
FROM [PortfolioProjects].[dbo].[online_retail];


--Remove Bad Records
--Filter the result set to exclude records where the customerID is blank. 
SELECT 
	*
FROM [PortfolioProjects].[dbo].[online_retail]
WHERE CustomerID ! ='';


--Check for Duplicate Rows
--Utilize Common Table Expressions (CTE's), and apply a query to filter for the relevant records.
--Pass clean data to a temp table
;WITH retail AS (
SELECT 
	*
FROM [PortfolioProjects].[dbo].[online_retail]
WHERE CustomerID ! =''
 ),
 quantity_unit_price AS (
 --347882 records with quantity and unit price
SELECT
	*
FROM retail
WHERE CAST(Quantity AS numeric) > 0 AND CAST(UnitPrice AS numeric) > 0
),
dup_check AS (
--Check for duplicate values.
SELECT 
	*, 
	ROW_NUMBER() OVER (PARTITION BY InvoiceNo, StockCode, CAST(Quantity AS numeric) ORDER BY CAST(InvoiceDate AS DATE)) AS dup
FROM quantity_unit_price
)
SELECT 
	* 
INTO #online_retail_clean
FROM dup_check
WHERE dup = 1;


--Retrieve all records from the #online_retail_clean temp table
SELECT * FROM #online_retail_clean;


--COHORT ANALYSIS
--The unique identifier (CustomerID) will be obtained and linked to the date of the first purchase (First Invoice Date).
--Pass data into a temp table (#cohort)
SELECT
	CustomerID,
	min(CAST( InvoiceDate AS Date)) AS first_purchase_date,
	DATEFROMPARTS(year(min(CAST( InvoiceDate AS Date))),month(min(CAST( InvoiceDate AS Date))),1) AS Cohort_Date
INTO #cohort
FROM #online_retail_clean
GROUP BY CustomerID;

--Calculate Cohort Index
--Join the #online_retail_clean and #cohort tables on CustomerID. 
--Retrieve the invoice dates and the cohort dates from each table
;WITH CTE AS(
SELECT
	o.*,
	c.Cohort_Date,
	year(CAST(o.InvoiceDate AS Date)) AS invoice_year,
	month(CAST(o.InvoiceDate AS Date)) AS invoice_month,
	year(CAST(c.Cohort_Date AS Date)) AS cohort_year,
	month(CAST(c.Cohort_Date AS Date)) AS cohort_month
FROM #online_retail_clean AS o
LEFT JOIN #cohort AS c
ON o.CustomerID=c.CustomerID
),
cte2 AS (
--Derive the year_diff and month_diff columns
SELECT 
	CTE.*,
	year_diff=invoice_year-cohort_year,
	month_diff=invoice_month-cohort_month
FROM CTE 
)
--Calculate cohort index
SELECT 
	cte2.*,
	year_diff*12+month_diff+1 AS cohort_index
--place CTE stack into a temp table #cohorts_retention
INTO #cohorts_retention
FROM cte2


--Select all columns from cohorts_retention temp table
SELECT * FROM #cohorts_retention;

SELECT DISTINCT customerID,
				Cohort_Date,
				cohort_index
FROM #cohorts_retention
ORDER BY CustomerID,cohort_index;


--Retrieve the unique customerID, cohort date and cohort index from #cohorts_retention
--Pass the above query into the PIVOT operator
--Pass the query into a temp table #cohort_pivot
SELECT
	*
INTO #cohort_pivot
FROM (
	SELECT DISTINCT 
		CustomerID,
		Cohort_Date,
		cohort_index
	FROM #cohorts_retention
	)tbl
PIVOT(
COUNT(CustomerID)
FOR Cohort_Index In ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13])

)AS PIVOT_TABLE
ORDER BY Cohort_Date
go


--Cohort Retention Rate
SELECT 
	Cohort_Date, 
	1.0*[1]/[1]*100 AS [1],
	1.0*[2]/[1]*100 AS [2],
	1.0*[3]/[1]*100 AS [3],
	1.0*[4]/[1]*100 AS [4],
	1.0*[5]/[1]*100 AS [5],
	1.0*[6]/[1]*100 AS [6],
	1.0*[7]/[1]*100 AS [7],
	1.0*[8]/[1]*100 AS [8],
	1.0*[9]/[1]*100 AS [9],
	1.0*[10]/[1]*100 AS [10],
	1.0*[11]/[1]*100 AS [11],
	1.0*[13]/[1]*100 AS [12],
	1.0*[13]/[1]*100 AS [13]
FROM #cohort_pivot;


--there are 13 distinct values in the cohort_index colunm
--SELECT DISTINCT
--		cohort_index
--	FROM #cohorts_retention

SELECT * FROM #cohort_pivot;