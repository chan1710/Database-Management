----------------------------------------------------------------------------
-- -- FUNCTION
----------------------------------------------------------------------------
-- ham co input CustomerId, output TotalAmount
-- xuat ra tong gia tien tu cac hoa don cua khach hang
CREATE FUNCTION ufn_SumOfOrderByCustomerId(@CustomerID INT)
RETURNS INT
AS
	BEGIN
		DECLARE @TotalAmountOrder INT

		SELECT @TotalAmountOrder = SUM(TotalAmount)
		FROM [Order]
		WHERE CustomerId = @CustomerID

		RETURN @TotalAmountOrder
	END
GO

SELECT *, 'SumOfOrders' = dbo.ufn_SumOfOrderByCustomerId(Id) 
FROM Customer
GO


-- ham input hai so, output danh sach cac san pham co UnitPrice trong khoang hai so do
CREATE FUNCTION ufn_ProductListByUnitPriceDesc(@Num1 INT, @Num2 INT)
RETURNS TABLE
AS
	RETURN
	(
		SELECT *
		FROM Product
		WHERE UnitPrice <= @Num2 AND UnitPrice >= @Num1
	)
GO

SELECT * 
FROM dbo.ufn_ProductListByUnitPriceDesc(1, 10)
GO


-- ham input danh sach cac thang, output thong tin cua hoa don co trong thang
-- viet dang inline va multi statement
CREATE VIEW uvw_OrderByMonth
AS
	SELECT Id, OrderNumber, CustomerId, TotalAmount,
		OrderMonth = 
		(
			CASE MONTH(OrderDate)
				WHEN 1 THEN 'January'
				WHEN 2 THEN 'February'
				WHEN 3 THEN 'March'
				WHEN 4 THEN 'Apirl'
				WHEN 5 THEN 'May'
				WHEN 6 THEN 'June'
				WHEN 7 THEN 'July'
				WHEN 8 THEN 'August'
				WHEN 9 THEN 'September'
				WHEN 10 THEN 'October'
				WHEN 11 THEN 'November'
				ELSE 'December'
			END
		)
	FROM [Order]
GO

CREATE FUNCTION ufn_OrderListByMonthFilter(@MonthFilter NVARCHAR(MAX))
RETURNS TABLE
AS
	RETURN
	(
		SELECT Id, OrderNumber, CustomerId, TotalAmount, OrderMonth
		FROM uvw_OrderByMonth
		WHERE CHARINDEX(LTRIM(RTRIM(LOWER(OrderMonth))), @MonthFilter) > 0
	)
GO

SET STATISTICS TIME ON
SELECT *
FROM ufn_OrderListByMonthFilter('June;July;August;September');
GO


-- ham kiem tra moi hoa don khong qua 5 san pham
-- neu qua 5 thi bao loi
CREATE FUNCTION ufn_CheckOrderItemExistence(@OrderId INT)
RETURNS BIT
AS 
	BEGIN
	DECLARE @Check BIT;

	IF 
	(
		EXISTS
		(
			SELECT OrderId, ProductId, UnitPrice, Quantity
			FROM [OrderItem]
			GROUP BY OrderId, ProductId, UnitPrice, Quantity
			HAVING COUNT(@OrderId) <= 5
		)
	)
		SET @Check = 1;
	ELSE
		SET @Check = 0;

	RETURN @Check
	END
GO


ALTER TABLE OrderItem
ADD CONSTRAINT CheckOrderItem
	CHECK (dbo.ufn_CheckOrderItemExistence(OrderId) = 1)
GO