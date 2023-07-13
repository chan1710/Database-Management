----------------------------------------------------------------------------
-- -- VIEW
----------------------------------------------------------------------------
-- tao cac view sau:
-- -- uvw_DetailProductInOrder (OrderId, OrderNumber, OrderDate, ProductId, ProductInfo(= ProductName + Package), UnitPrice, Quantity)
CREATE VIEW uvw_DetailProductInOrder
AS
	SELECT OrI.OrderId, Ord.OrderNumber, Ord.OrderDate, OrI.ProductId, 
			ProductInfo = Pro.ProductName + ' x ' + Pro.Package, 
			OrI.UnitPrice, OrI.Quantity
	FROM [OrderItem] OrI
	LEFT JOIN [Order] Ord ON Ord.Id = OrI.Id
	LEFT JOIN [Product] Pro ON Pro.Id = OrI.ProductId
GO

-- -- uvw_AllProductInOrder (OrderId, OrderNumber, OrderDate, ProductList, TotalAmount (=SUM(UnitPrice*Quantity)) theo OrderId)
CREATE VIEW uvw_AllProductInOrder
AS
	SELECT DISTINCT OrI.OrderId, Ord.OrderNumber, Ord.OrderDate,
		ProductList = STUFF( 
		(
			SELECT ', ' + CONVERT(VARCHAR, Pro.Id)
			FROM [OrderItem] Ori
			LEFT JOIN Product Pro ON Pro.Id = Ori.ProductId
			WHERE Ori.OrderId = OrI.OrderId
			ORDER BY Pro.Id
			FOR XML PATH('')
		)
		, 1, 1, '')
	FROM [OrderItem] OrI
	INNER JOIN [Order] Ord ON Ord.Id = OrI.OrderId
	GROUP BY OrI.OrderId, Ord.OrderNumber, Ord.OrderDate
GO


-- dung view uvw_DetailProductInOrder truy van nhung thong tin co OrderDate trong thang 7
SELECT *
FROM uvw_DetailProductInOrder
WHERE MONTH(OrderDate) = '7'
GO


-- dung view uvw_AllProductInOrder truy van nhung hoa don co it nhat 3 product tro len
SELECT *
FROM uvw_AllProductInOrder
WHERE ProductList LIKE '%, %, %'
GO


-- readonly? su dung UPDATE de check
UPDATE uvw_DetailProductInOrder SET Quantity = 12
WHERE ProductId = 11 AND OrderId = 1
GO

-- => chua readonly
-- -- tao trigger
CREATE TRIGGER uvw_DetailProductInOrder_1
ON uvw_DetailProductInOrder
INSTEAD OF INSERT, UPDATE, DELETE
AS
	BEGIN
		RAISERROR('no insert, update, delete', 16, 1)
	END
GO

-- -- them UNION
CREATE VIEW uvw_DetailProductInOrder_2
AS
	SELECT OrI.OrderId, Ord.OrderNumber, Ord.OrderDate, OrI.ProductId, 
			ProductInfo = Pro.ProductName + ' x ' + Pro.Package, 
			OrI.UnitPrice, OrI.Quantity
	FROM [OrderItem] OrI
	LEFT JOIN [Order] Ord ON Ord.Id = OrI.Id
	LEFT JOIN [Product] Pro ON Pro.Id = OrI.ProductId
	UNION
	SELECT Null, Null, Null, Null, Null, Null, Null
	WHERE 1 = 0
GO

-- -- them WITH CHECK OPTION
CREATE VIEW uvw_DetailProductInOrder_3
AS
	WITH CheckProduct(OrderId, ProductInfo)
	AS 
	(
		SELECT OrderId, ProductInfo = Pro.ProductName + ' x ' + Pro.Package
		FROM [OrderItem] OrI
		LEFT JOIN [Product] Pro ON Pro.Id = OrI.ProductId
		GROUP BY OrderId, Pro.ProductName, Pro.Package
	)
	SELECT OrI.OrderId, Ord.OrderNumber, Ord.OrderDate, OrI.ProductId, 
			ProductInfo = Pro.ProductName + ' x ' + Pro.Package, 
			OrI.UnitPrice, OrI.Quantity
	FROM [OrderItem] OrI
	LEFT JOIN [Order] Ord ON Ord.Id = OrI.Id
	LEFT JOIN [Product] Pro ON Pro.Id = OrI.ProductId
	INNER JOIN [CheckProduct] Che ON Che.OrderId = OrI.OrderId
	WHERE Che.ProductInfo = Pro.ProductName + ' x ' + Pro.Package
	WITH CHECK OPTION;
GO


-- thong ke thoi gian thuc thi
SET STATISTICS IO, TIME ON
GO

SELECT *
FROM uvw_DetailProductInOrder
WHERE YEAR(OrderDate) = 2013

SELECT *
FROM uvw_AllProductInOrder
WHERE YEAR(OrderDate) = 2013

SET STATISTICS IO, TIME ON
GO