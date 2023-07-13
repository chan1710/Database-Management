----------------------------------------------------------------------
-- sap xep san pham tang dan theo UnitPrice, tim 20% dong co UnitPrice cao nhat
SELECT *
FROM 
(
	SELECT RowNum, Id, ProductName, SupplierId, Package, MAX(RowNum) OVER (ORDER BY (SELECT 1)) AS RowLast
	FROM 
	(
		SELECT ROW_NUMBER() OVER (ORDER BY UnitPrice) AS RowNum, Id, ProductName, SupplierId, Package
		FROM Product
	) AS DerivedTable
) AS Report
WHERE Report.RowNum >= 0.2*RowLast;


-- xuat danh sach cac san pham so luong (Quantity) va so phan tram cua san pham do trong hoa don
SELECT Id, OrderId, ProductId, Quantity, STR([Percent]*100, 5, 2) + '%' AS [Percent]
FROM
(
	SELECT Id, OrderId, ProductId, Quantity,
		Quantity/(CAST(SUM(Quantity) OVER (PARTITION BY OrderId) AS DECIMAL(5, 2))) AS [Percent]
	FROM OrderItem
) AS Report
ORDER BY OrderId, ProductId


-- xuat danh sach cac nha cung cap kem theo cot USA, UK, France, Germany, Others va danh so
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SuplierCountry')
BEGIN
	DROP TABLE SupplierCountry
END

SELECT Id, Country,
	(
		CASE Country
			WHEN 'USA' THEN 'USA'
			WHEN 'UK' THEN 'UK'
			WHEN 'France' THEN 'France'
			WHEN 'Germany' THEN 'Germany'
			ELSE 'Others'
		END
	) AS SupCountry,
	(
		CASE
			WHEN Country IN ('USA', 'UK', 'France', 'Germany') THEN 1
			ELSE 0
		END 
	) AS Number INTO SupplierCountry
FROM Supplier

SELECT * 
FROM SupplierCountry

SELECT SupCou.Id, Sup.CompanyName, Sup.Phone, SupCou.Country, SupCou.Number, Sup.ContactName,
	SupCou.USA, SupCou.UK, SupCou.France, SupCou.Germany, SupCou.Others
FROM
(
	SELECT *
	FROM SupplierCountry
	PIVOT (COUNT(SupCountry) FOR SupCountry IN ([USA], [UK], [France], [Germany], [Others])) AS PivotSup
) AS SupCou
INNER JOIN Supplier AS Sup
ON SupCou.Id = Sup.Id;


-- xuat danh sach  cac hoa don gom OrderNumber, OrderDate, CustomerName, Address, TotalAmount
SELECT Ord.OrderNumber,
	[Date] = STR(DAY(Ord.OrderDate), LEN(DAY(Ord.OrderDate)), 0) + ' ' + STR(MONTH(Ord.OrderDate), LEN(MONTH(Ord.OrderDate)), 0) + ' ' + STR(YEAR(Ord.OrderDate), 4, 0),
	[Name] = Cus.FirstName + ' ' + Cus.LastName,
	[Address] = 'Phone:' + Cus.Phone + ', City:' + Cus.City + ', Country:' + Cus.Country,
	[TotalAmount] = STR(ROUND(TotalAmount, 0), LEN(TotalAmount), 0) + '$'
FROM [Order] AS Ord, Customer AS Cus
WHERE Ord.CustomerId = Cus.Id;


-- xuat danh sach cac san pham duoi dang dong goi bags, thay bags thanh 'túi'
SELECT Id, ProductName, SupplierId, UnitPrice,
	[Package] = STUFF(Package, CHARINDEX('bags', Package), LEN('bags'), N'túi')
FROM Product
WHERE Package LIKE '%bags%';


-- xuat danh sach cac khach hang theo tong so hoa don ma khach hang do co, sap xep theo thu tu giam dan cua tong so hoa don, kem theo cac thong tin phan hang va nhom
SELECT [CustomerID] = Report.Id, 
	[CustomerName] = Report.FirstName + ' ' + Report.LastName,
	[TotalOrder] = Report.TotalOrder,
	[Rank] = DENSE_RANK() OVER (ORDER BY Report.TotalOrder),
	[Group] = NTILE(3) OVER (ORDER BY Report.TotalOrder DESC)
FROM
(
	SELECT Cus.Id, Cus.FirstName, Cus.LastName, [TotalOrder] = COUNT(ISNULL(Ord.CustomerId, 0))
	FROM Customer AS Cus
	LEFT JOIN [Order] AS Ord ON Cus.Id = Ord.CustomerId
) AS Report;


----------------------------------------------------------------------
-- theo moi OrderId cho biet so luong Quantity cua moi ProductId chiem ty le bao nhieu phan tram
SELECT OrderId, ProductId, Quantity,
	SUM(Quantity) OVER (PARTITION BY ProductId) AS QuantityByOrderId,
	Quantity/(CAST(SUM(Quantity) OVER (PARTITION BY OrderId) AS DECIMAL(5, 2))) AS PercentByOrderId
FROM OrderItem
ORDER BY ProductId, OrderId


-- xuat cac hoa don kem theo thong tin ngay trong tuan cua hoa don
SELECT *,
	(
		CASE DATENAME(dw, OrderDate)
			WHEN 'Monday' THEN 'Thu 2'
			WHEN 'Tuesday' THEN 'Thu 3'
			WHEN 'Wednesday' THEN 'Thu 4'
			WHEN 'Thusday' THEN 'Thu 5'
			WHEN 'Friday' THEN 'Thu 6'
			WHEN 'Satuday' THEN 'Thu 7'
			ELSE 'Chu nhat'
		END
	) AS [DayName]
FROM [Order]


-- voi moi ProductId trong Orderitem xuat cac thong tin OrderId, ProductId, ProductName, UnitPrice, Quantity, ContactInfo, ContactType.
-- trong do contactInfo uu tien Fax, neu khong thi dung Phone cua Supplier san pham do, ContactType la ghi chu do la loai ContactInfo nao
SELECT OrI.Quantity, OrI.OrderId, OrI.UnitPrice, OrI.ProductId, Pro.ProductName,
	COALESCE(Fax, Phone) AS ContactInfo,
	CASE COALESCE(Fax, Phone) 
		WHEN Fax THEN 'Fax' 
		ELSE 'Phone' 
	END AS ContactType
FROM OrderItem AS OrI
LEFT JOIN Product AS Pro ON OrI.ProductId = Pro.Id
LEFT JOIN Supplier AS Sup ON Sup.Id = Pro.SupplierId


-- dung WITH phan chia cay nhu sau: 0 Country, 1 City thuoc Country, 2 Order tu khach hang Country-City
WITH CustomerCategory(Id, Country, City, FirstName, LastName, alevel) AS
(
	SELECT DISTINCT Id, Country, City = CAST('' AS NVARCHAR(255)),
		FirstName = CAST('' AS NVARCHAR(255)),
		LastName = CAST('' AS NVARCHAR(255)),
		alevel = 0
	FROM Customer

	UNION ALL

	SELECT Cus.Id, Cus.Country, City = CAST(Cus.City AS NVARCHAR(255)),
		FirstName = CAST('' AS NVARCHAR(255)),
		LastName = CAST('' AS NVARCHAR(255)),
		alevel = CuC.alevel + 1
	FROM CustomerCategory AS CuC
	INNER JOIN Customer AS Cus ON CuC.Country = Cus.Country

	UNION ALL

	SELECT Cus.Id, Cus.Country, City = CAST(Cus.City AS NVARCHAR(255)),
		FirstName = CAST('' AS NVARCHAR(255)),
		LastName = CAST('' AS NVARCHAR(255)),
		alevel = CuC.alevel + 1
	FROM CustomerCategory AS CuC
	INNER JOIN Customer AS Cus ON Cus.Country = CuC.Country AND CuC.City = Cus.City
	WHERE CuC.alevel = 1
)

SELECT [Country] = CASE WHEN alevel = 0 THEN Country ELSE '--' END,
	[City] = CASE WHEN alevel = 1 THEN City ELSE '--' END,
	[Order] = Ord.Id,
	[Level] = alevel
FROM CustomerCategory AS CuC
LEFT JOIN [Order] AS Ord ON CuC.Id = Ord.CustomerId
ORDER BY Country, City, FirstName, LastName, alevel


-- xuat nhung hoa don tu khach hang France ma co tong so luong Quantity lon hon 50 cua cac san pham thuoc hao don ay
WITH 
	SumByOrder AS
	(
		SELECT OrderId, SumQuantity = SUM(Quantity)
		FROM [OrderItem] AS OrI
		LEFT JOIN [Order] AS Ord ON Ord.Id = OrI.OrderId
		LEFT JOIN Customer AS Cus ON Cus.Id = Ord.CustomerId
		WHERE Cus.Country = 'France'
		HAVING SUM(Quantity) = 50
	),
	OrderByCountry AS
	(
		SELECT OrI.*, Cus.Country
		FROM OrderItem AS OrI
		LEFT JOIN [Order] AS Ord ON Ord.Id = OrI.OrderId
		LEFT JOIN Customer AS Cus ON Ord.CustomerId = Cus.Id
		WHERE Cus.Country = 'France'
	)
SELECT *
FROM OrderByCountry
WHERE Quantity > ALL(SELECT SumQuantity FROM SumByOrder)