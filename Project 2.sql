


-- Course 92700.1, Oren Ben Hen, ID: 033737982

/*
Hi Sima, struggled with some of the questions, I would appreciate you remarking the code
with any suggestions/better solution/redundant code if needed.

My goal is to Excel in SQL...

*/




USE WideWorldImporters


--Exercise 1
SELECT SQ.InvoiceYear
	  ,FORMAT(SQ.IncomePerYear, 'N2') AS IncomePerYear
	  ,SQ.NumberOfDistinctMonth AS NumberOfDistinctMonth
	  ,FORMAT(SQ.YearlyLinearIncome, 'N2') AS YearlyLinearIncome
	  ,FORMAT(((SQ.YearlyLinearIncome - SQ.IncomePerLastYear) /  SQ.IncomePerLastYear * 100), 'N2') AS GrowthRate
FROM(SELECT YEAR(i.InvoiceDate) AS InvoiceYear
		   ,SUM(il.ExtendedPrice - il.TaxAmount) AS IncomePerYear
		   ,LAG(SUM(il.ExtendedPrice - il.TaxAmount)) OVER(ORDER BY YEAR(i.InvoiceDate)) AS IncomePerLastYear
		   ,COUNT(DISTINCT DATEPART(MM, i.InvoiceDate)) AS NumberOfDistinctMonth
	       ,SUM(il.ExtendedPrice - il.TaxAmount) / COUNT(DISTINCT DATEPART(MM, i.InvoiceDate)) * 12 AS YearlyLinearIncome
	 FROM sales.invoices AS i JOIN sales.InvoiceLines AS il
	 ON i.InvoiceID = il.InvoiceID
	 GROUP BY YEAR(i.InvoiceDate)) AS SQ


--Exercise 2
GO
WITH tbl
AS(
SELECT YEAR(inv.invoicedate) AS TheYear
	  ,DATEPART(Q, inv.invoicedate) AS TheQuarter
	  ,cust.CustomerName
	  ,SUM(il.ExtendedPrice - il.TaxAmount) AS IncomePerQuarterYear
	  ,DENSE_RANK() OVER(PARTITION BY YEAR(inv.invoicedate), DATEPART(Q, inv.invoicedate) ORDER BY SUM(il.ExtendedPrice - il.TaxAmount) DESC) as DNR
FROM sales.invoices as inv JOIN sales.customers AS cust
ON inv.customerID = cust.CustomerID
	JOIN sales.invoiceLines as il
ON inv.invoiceID = il.invoiceID
GROUP BY YEAR(inv.invoicedate), DATEPART(Q, inv.invoicedate) , cust.customerName)

SELECT *
FROM tbl
WHERE DNR BETWEEN 1 AND 5


--Exercise 3
SELECT TOP 10 il.StockItemID AS StockItemID
			 ,si.StockItemName AS StockItemName
	         ,SUM(il.ExtendedPrice - il.TaxAmount) AS TotalProfit
FROM sales.invoicelines AS il JOIN warehouse.StockItems AS si
ON il.stockitemID = si.stockitemID
GROUP BY il.StockItemID, si.StockItemName
ORDER BY TotalProfit DESC


--Exercise 4
SELECT ROW_NUMBER() OVER(ORDER BY si.RecommendedRetailPrice - si.UnitPrice DESC) AS RN
	  ,si.stockitemID
	  ,si.stockitemName
	  ,si.unitprice
	  ,si.RecommendedRetailPrice
	  ,si.RecommendedRetailPrice - si.UnitPrice AS NominalProductProfit
	  ,DENSE_RANK() OVER(ORDER BY si.RecommendedRetailPrice - si.UnitPrice DESC) AS DNR
FROM warehouse.stockitems AS si
WHERE DATEDIFF(d, si.ValidFrom, si.ValidTo) > 0


--Exercise 5
SELECT CONCAT_WS(' - ', si.supplierID, su.SupplierName) AS SupplierDetails
	  ,STRING_AGG(CONCAT(si.stockitemID ,+ ' ' + si.stockitemname), '/, ') AS ProductDetails
FROM warehouse.stockitems as si JOIN purchasing.suppliers as su
ON si.supplierID = su.supplierID
GROUP BY si.supplierID, su.SupplierName


--Exercise 6
SELECT TOP 5 inv.customerID AS CustomerID
	  ,ct.cityName AS CityName
	  ,co.countryName AS CountryName
	  ,co.Continent AS Continent
	  ,co.region AS Region
	  ,SUM(il.ExtendedPrice) AS TotalExtendedPrice
FROM sales.invoices AS inv JOIN sales.invoicelines as il 
ON inv.InvoiceID = il.InvoiceID
	JOIN sales.customers AS cu
ON cu.customerID = inv.CustomerID
	JOIN application.cities as ct
ON cu.DeliveryCityID = ct.CityID
AND cu.PostalCityID = ct.CityID
	JOIN application.StateProvinces as sp
ON sp.StateProvinceID = ct.StateProvinceID
	JOIN application.Countries as co
ON sp.countryID = co.CountryID
GROUP BY inv.customerID, ct.cityName ,co.countryName ,co.Continent ,co.region
ORDER BY TotalExtendedPrice DESC


--Exercise 7
SELECT InvoiceYear
	  ,InvoiceMonth
	  ,FORMAT(MonthlyTotal, 'N2') AS MonthlyTotal
	  ,FORMAT(CumulativeTotal, 'N2') AS CumulativeTotal
FROM 
	((SELECT InvoiceYear
		    ,CAST(InvoiceMonth AS VARCHAR) AS InvoiceMonth
		    ,MonthlyTotal
		    ,SUM(MonthlyTotal) OVER(ORDER BY SortOrder ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeTotal
	  FROM
		(SELECT *
			   ,DENSE_RANK() OVER(ORDER BY InvoiceYear, InvoiceMonth, MonthlyTotal DESC) AS SortOrder   
		 FROM
		   (SELECT YEAR(inv.invoicedate) AS InvoiceYear
				  ,DATEPART(MM, inv.invoicedate) AS InvoiceMonth
				  ,SUM(il.ExtendedPrice - il.TaxAmount) AS MonthlyTotal

			FROM sales.invoices AS inv JOIN sales.invoicelines AS il
			ON inv.invoiceID = il.invoiceID
				JOIN sales.Orders as ord
			ON ord.orderID = inv.OrderID
			GROUP BY YEAR(inv.invoicedate), DATEPART(MM, inv.invoicedate)) AS SQ1) AS SQ2)
UNION
	(SELECT *
		   ,MonthlyTotal
	 FROM
		(SELECT YEAR(inv.invoicedate) AS InvoiceYear
   				,'Grand Total' AS InvoiceMonth
				,SUM(il.ExtendedPrice - il.TaxAmount) AS MonthlyTotal
		 FROM sales.invoices AS inv JOIN sales.invoicelines AS il
		 ON inv.invoiceID = il.invoiceID
			JOIN sales.Orders as ord
		 ON ord.orderID = inv.OrderID
		 GROUP BY YEAR(inv.invoicedate)) AS SQ3)) AS SQ4
ORDER BY InvoiceYear, CASE WHEN InvoiceMonth = 'Grand Total' THEN 100 ELSE InvoiceMonth END -- ASCII for 12 = 99


--Exercise 8
SELECT OrderMonth,[2013],[2014],[2015],[2016]
FROM(SELECT YEAR(ord.OrderDate) OrderYear
		   ,MONTH(ord.OrderDate) AS OrderMonth
		   ,ord.OrderID AS OrderID
     FROM sales.orders as ord) SQ
PIVOT (COUNT(OrderID) FOR OrderYear IN([2013],[2014],[2015],[2016])) AS pvt
ORDER BY OrderMonth


--Exercise 9
GO
WITH tbl
AS
(SELECT CustomerID 
	   ,CustomerName
	   ,OrderDate
	   ,PreviousOrderDate
	   ,DATEDIFF(d, FirstOrder, LastCustOrderDate) / NumOrders AS AvgDaysBetweenOrders
	   ,LastCustOrderDate
	   ,LastOrderDateAll
	   ,DATEDIFF(d, LastCustOrderDate, LastOrderDateAll) AS DaysSinceLastOrder
 FROM(SELECT ord.customerID AS CustomerID
			,cu.CustomerName AS CustomerName
			,ord.orderdate AS OrderDate
			,LAG(ord.OrderDate) OVER(PARTITION BY ord.customerID ORDER BY ord.OrderDate) AS PreviousOrderDate
			,MIN(ord.orderdate) OVER(PARTITION BY ord.customerID ORDER BY ord.customerID) AS FirstOrder
			,COUNT(ord.customerID) OVER(PARTITION BY ord.customerID ORDER BY ord.customerID) AS NumOrders
			,MAX(ord.orderdate) OVER(PARTITION BY ord.customerID) AS LastCustOrderDate
			,MAX(ord.orderdate) OVER() AS LastOrderDateAll
	  FROM sales.orders as ord JOIN sales.customers as cu
	  ON ord.CustomerID = cu.CustomerID) AS SQ)
SELECT *
	  ,CASE WHEN DaysSinceLastOrder > (AvgDaysBetweenOrders * 2) THEN 'Potential Churn'
			ELSE 'Active'
	   END AS CustomerStatus
FROM tbl


--Exercise 10
GO
WITH tbl
AS
(SELECT CustomerCategoryName
		,COUNT(Gen_CustomerName) OVER(PARTITION BY CustomerCategoryName) AS CustomerCount
	    ,COUNT(*) OVER() AS TotalCustCount
 FROM
(SELECT CASE WHEN cu.CustomerName LIKE 'Tailspin%' THEN 'Tailspin'
			 WHEN cu.CustomerName LIKE 'Wingtip%' THEN 'Wingtip'
			 ELSE cu.CustomerName
	    END AS Gen_CustomerName
	   ,cc.CustomerCategoryName AS CustomerCategoryName
 FROM sales.customers AS cu JOIN sales.customercategories AS cc
 ON cu.customercategoryID = cc.customercategoryID) AS SQ
 GROUP BY CustomerCategoryName ,Gen_CustomerName)

SELECT *
	  ,FORMAT((CAST(CustomerCount AS FLOAT) / CAST(TotalCustCount AS FLOAT)) , 'P') AS DistributionFactor
FROM tbl
GROUP BY CustomerCategoryName, CustomerCount, TotalCustCount





















