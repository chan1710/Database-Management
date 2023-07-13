----------------------------------------------------------------------
-- truy van danh sach cac Customer
SELECT *
FROM Customer;

-- truy van danh sach cac Customer theo cac thong tin Id, FullName (FirstName - LastName), City, Country
SELECT Id, CONCAT(FirstName, ' ', LastName) AS FullName, City, Country
FROM Customer;

-- truy van so khach hang den tu Germany va UK, thong tin khach hang
SELECT CONCAT(FirstName, ' ', LastName) AS FullName, City, Country
FROM Customer
WHERE Country = 'Germany' OR Country = 'UK';

SELECT COUNT(Id) AS Amount
FROM Customer
WHERE Country = 'Germany' OR Country = 'UK';

-- truy van danh sach khach hang theo thu tu tang dan cua FirstName va giam dan Country
SELECT Id, CONCAT(FirstName, ' ', LastName) AS FullName, City, Country
FROM Customer
ORDER BY FirstName ASC, Country DESC;

-- truy van danh sach khach hang voi ID la 5, 10, tu 1-10 va 5-10
SELECT Id, CONCAT(FirstName, ' ', LastName) AS FullName, City, Country
FROM Customer
WHERE Id = 5 OR Id = 10;

SELECT TOP 10 Id, CONCAT(FirstName, ' ', LastName) AS FullName, City, Country
FROM Customer;

SELECT Id, CONCAT(FirstName, ' ', LastName) AS FullName, City, Country
FROM Customer
ORDER BY Id
OFFSET 4 ROWS
FETCH NEXT 6 ROWS ONLY;

-- truy van cac khach hang o cac san pham (Product) ma dong goi duoi dang bottles co gia tri tu 15 den 20 ma khong tu nha cung cap co Id 16
SELECT Id, CONCAT(FirstName, ' ', LastName) AS FullName, City, Country
FROM Customer AS Cus
WHERE Cus.Id In 
(
	SELECT Pro.Id
	FROM Product AS Pro
	WHERE Pro.SupplierId != 16 AND Pro.Package LIKE '%bottles%' AND Pro.UnitPrice BETWEEN 15 AND 20
);


----------------------------------------------------------------------
-- truy van danh sach nha cung cap (Id, CompanyName, ContactName, City, Phone) kem theo Min va Max gia cua san pham ma nha cung cap do cung cap, dong thoi sap xep theo thu tu Id cua nha cung cap
SELECT Sup.Id, Sup.CompanyName, Sup.ContactName, Sup.City, Sup.Phone,
	MIN(Pro.UnitPrice) AS 'Min Price',
	MAX(Pro.UnitPrice) AS 'Max Price'
FROM Supplier AS Sup
INNER JOIN Product AS Pro ON Sup.Id = Pro.SupplierId
GROUP BY Sup.Id, Sup.CompanyName, Sup.ContactName, Sup.City, Sup.Phone
ORDER BY Sup.Id DESC;


-- tuong tu tren, truy van danh sach nha cung cap co su khac biet gia (Max - Min) khong qua lon (<=30)
SELECT Sup.Id, Sup.CompanyName, Sup.ContactName, Sup.City, Sup.Phone,
	MIN(Pro.UnitPrice) AS 'Min Price',
	MAX(Pro.UnitPrice) AS 'Max Price'
FROM Supplier AS Sup
INNER JOIN Product AS Pro ON Sup.Id = Pro.SupplierId
GROUP BY Sup.Id, Sup.CompanyName, Sup.ContactName, Sup.City, Sup.Phone
HAVING MAX(Pro.UnitPrice) - MIN(Pro.UnitPrice) <= 30
ORDER BY Sup.Id DESC;

-- truy van danh sach hoa don (Id, OrderNumber, OrderDate) kem theo tong gia chi tra (UnitPrice*Quantity) cho hoa don, ben canh Description la 'VIP' neu tong gia >1500 va 'Normal' neu tong gia <=1500
SELECT Ord.Id, Ord.OrderNumber, Ord.OrderDate, Price.total AS 'Sum Price', 'VIP' AS 'Description'
FROM 
(
	SELECT OrderId, SUM(OrI.Quantity*OrI.UnitPrice) AS 'total'
	FROM OrderItem AS OrI
	GROUP BY OrderId
	HAVING SUM(OrI.Quantity*OrI.UnitPrice) > 1500
) AS [Price]
LEFT JOIN [Order] AS Ord
ON Price.OrderId = Ord.Id
UNION
SELECT Ord.Id, Ord.OrderNumber, Ord.OrderDate, Price.total AS 'Sum Price', 'Normal' AS 'Description'
FROM 
(
	SELECT OrderId, SUM(OrI.Quantity*OrI.UnitPrice) AS 'total'
	FROM OrderItem AS OrI
	GROUP BY OrderId
	HAVING SUM(OrI.Quantity*OrI.UnitPrice) <= 1500
) AS [Price]
LEFT JOIN [Order] AS Ord
ON Price.OrderId = Ord.Id

SELECT Ord.Id, Ord.OrderNumber, Ord.OrderDate, SUM(OrI.UnitPrice*OrI.Quantity) AS 'total',
	(
		CASE
			WHEN SUM(OrI.UnitPrice*OrI.Quantity) > 1500 THEN 'VIP'
			WHEN SUM(OrI.UnitPrice*OrI.Quantity) <= 1500 THEN 'Normal'
		END
	) AS 'Description'
FROM [Order] AS Ord
LEFT JOIN OrderItem AS OrI
ON OrI.OrderId = Ord.Id
GROUP BY Ord.Id, Ord.OrderNumber, Ord.OrderDate

-- truy xuat danh sach nhung hoa don (Id, OrderNumber, OrderDate) trong thang 7 nhung ngoai tru hoa don tu khach hang France
SELECT Ord.Id, Ord.OrderDate, Ord.OrderNumber
FROM Customer AS Cus, [Order] AS Ord
WHERE EXISTS 
(
	SELECT *
	FROM [Order] 
	WHERE Ord.CustomerId = Cus.Id AND MONTH(Ord.OrderDate) = 7
)
EXCEPT
SELECT Ord.Id, Ord.OrderDate, Ord.OrderNumber
FROM Customer AS Cus, [Order] AS Ord
WHERE  Cus.Country = 'France' AND EXISTS 
(
	SELECT *
	FROM [Order] 
	WHERE Ord.CustomerId = Cus.Id AND MONTH(Ord.OrderDate) = 7
);

SELECT Ord.Id, Ord.OrderDate, Ord.OrderNumber
FROM [Order] AS Ord
JOIN Customer AS Cus
ON Cus.Id = Ord.CustomerId
WHERE Cus.Country != 'France' AND MONTH(Ord.OrderDate) = 7;

-- truy xuat danh sach nhung hoa don (Id, OrderNumber, OrderDate, TotalAmount) nao co TotalAount nam trong top 5 cac hoa don
SELECT Id, OrderDate, OrderNumber, TotalAmount
FROM [Order]
WHERE TotalAmount IN 
(
	SELECT TOP 5 TotalAmount
	FROM [Order]
	ORDER BY TotalAmount DESC
);