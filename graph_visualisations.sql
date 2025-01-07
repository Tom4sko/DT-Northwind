SELECT 
    p.ProductName,
    SUM(f.Quantity) AS TotalQuantitySold,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimProduct p ON f.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalSales DESC
LIMIT 10;

SELECT 
    p.ProductName,
    SUM(f.Quantity) AS TotalQuantitySold,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimProduct p ON f.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalSales ASC
LIMIT 10;

SELECT 
    c.Country,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimCustomer c ON f.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY TotalSales DESC;

SELECT 
    s.SupplierName,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimProduct p ON f.ProductID = p.ProductID
JOIN Suppliers s ON p.SupplierID = s.SupplierID
GROUP BY s.SupplierName
ORDER BY TotalSales DESC
LIMIT 5;

SELECT 
    s.SupplierName,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimProduct p ON f.ProductID = p.ProductID
JOIN Suppliers s ON p.SupplierID = s.SupplierID
GROUP BY s.SupplierName
ORDER BY TotalSales ASC
LIMIT 5;

SELECT 
    d.Month,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimDate d ON f.Date = d.Date
GROUP BY d.Month
ORDER BY d.Month
LIMIT 10;

SELECT 
    d.Month,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimDate d ON f.Date = d.Date
GROUP BY d.Month
ORDER BY d.Month;

SELECT 
    f.OrderID,
    SUM(f.TotalSales) AS OrderValue
FROM FactSales f
GROUP BY f.OrderID;

SELECT AVG(OrderValue) AS AverageOrderValue
FROM (
    SELECT 
        f.OrderID,
        SUM(f.TotalSales) AS OrderValue
    FROM FactSales f
    GROUP BY f.OrderID
) subquery;

SELECT 
    d.Month,
    COUNT(DISTINCT f.OrderID) AS TotalOrders
FROM FactSales f
JOIN DimDate d ON f.Date = d.Date
GROUP BY d.Month
ORDER BY d.Month
LIMIT 10;
