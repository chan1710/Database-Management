--------------------------------------------------------------------------
-- Stored Procedure
--------------------------------------------------------------------------
-- viet stored procedure input CustomerId, output OrderId cua khach hang co ToatlAmount min, OrderId cuar khach hang co TotalAMount max
CREATE PROCEDURE usp_GetOrderIdWithCustomerId
	@CustomerId INT,
	@MaxOrderId INT OUTPUT,
	@MaxTotalAmount DECIMAL(12, 2) OUTPUT,
	@MinOrderId INT OUTPUT,
	@MinTotalAmount DECIMAL(12, 2) OUTPUT
AS
BEGIN
	WITH CustomerInfo(Id, TotalAmount, RowNum)
	AS
	(
		SELECT Id, TotalAmount, RowNum = ROW_NUMBER() OVER (ORDER BY TotalAmount Desc)
		FROM [Order]
		WHERE CustomerId = @CustomerId
	)

	SELECT @MaxOrderId = MAX(Id),
		@MaxTotalAmount = MAX(TotalAmount),
		@MinOrderId = MIN(Id),
		@MinTotalAmount = MIN(TotalAmount)
	FROM CustomerInfo
END

DECLARE @CustomerId INT
DECLARE @MaxOrderId INT
DECLARE @MaxTotalAmount DECIMAL (12, 2)
DECLARE @MinOrderId INT
DECLARE @MinTotalAmount DECIMAL (12, 2)
SET @CustomerId = 20
EXEC usp_GetOrderIdWithCustomerId @CustomerId, @MaxOrderId OUTPUT, @MaxTotalAmount OUTPUT, @MinOrderId OUTPUT, @MinTotalAmount OUTPUT
SELECT CustomerId = @CustomerId,
	MaxOrderId = @MaxOrderId,
	MaxTotalAmount = @MaxTotalAmount,
	MinOrderId = @MinOrderId,
	MinTotalAmount = @MinTotalAmount


-- viet stored procedure de them vao Customer, input FirstName, LastName, City, Country, Phone
CREATE PROCEDURE usp_InsertNewCustomer
	@FirstName NVARCHAR(50),
	@LastName NVARCHAR(50),
	@City NVARCHAR(50),
	@Country NVARCHAR(50),
	@Phone NVARCHAR(50)
AS
BEGIN
	IF 
	(
		EXISTS
		(
			SELECT FirstName, LastName, City, Country, Phone
			FROM Customer
			WHERE FirstName = @FirstName 
				AND LastName = @LastName
				AND City = @City
				AND Country = @Country
				AND Phone = @Phone
		)
	)
	BEGIN
		PRINT 'EXISTS'
		RETURN -1
	END

	BEGIN TRY
		BEGIN TRANSACTION 
			INSERT INTO Customer(FirstName, LastName, City, Country, Phone)
			VALUES (@FirstName, @LastName, @City, @Country, @Phone)
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		DECLARE @ERR NVARCHAR(MAX)
		SET @ERR = ERROR_MESSAGE()
		RAISERROR(@ERR, 16, 1)
		RETURN -1
	END CATCH
END

DECLARE @StateInsert INT
EXEC @StateInsert = usp_GetOrderIdWithCustomerId 'a', 'b', 'c', 'd', '1'
PRINT @StateInsert


-- viet stored procedure cap nhat lai UnitPrice cua san pham trong OrderItem, TotalAmount = SUM(UnitPrice*Quantity)
CREATE PROCEDURE usp_UpdateUnitPriceOfOrderItem
	@UnitPrice INT,
	@OrderId INT
AS
BEGIN
	IF (LEN(@UnitPrice) = 0)
	BEGIN
		PRINT 'null'
		RETURN -1
	END

	BEGIN TRY
		BEGIN TRANSACTION
			UPDATE OrderItem SET UnitPrice = @UnitPrice
			WHERE OrderId = @OrderId
			UPDATE [Order] SET TotalAmount = 
			(
				SELECT SUM(UnitPrice*Quantity)
				FROM [OrderItem]
				WHERE OrderId = @OrderId
			)
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		DECLARE @ERR NVARCHAR(MAX)
		SET @ERR = ERROR_MESSAGE()
		RAISERROR(@ERR, 16, 1)
		RETURN -1
	END CATCH
END

DECLARE @StateInsert INT
EXEC @StateInsert = usp_UpdateUnitPriceOfOrderItem 12, 1
PRINT @StateInsert