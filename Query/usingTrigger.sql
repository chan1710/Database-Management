----------------------------------------------------------------------------
-- -- TRIGGER - TRANSACTION - CURSOR - TEMP TABLE
----------------------------------------------------------------------------
-- trigger
-- viet trigger khi xoa PrderId thi xoa luon cac thong tin cua Order/OrderItem
-- Foreign Key Constraint xay ra thi khong xoa
CREATE TRIGGER dbo.Trigger_OrderDelete
ON [OrderItem]
FOR DELETE
AS
	DECLARE @DeleteOrderId INT
	
	SELECT @DeleteOrderId = OrderId
	FROM deleted

	PRINT 'Cac Order cua OrderId = ' + LTRIM(STR(@DeleteOrderId)) + ' da xoa'
GO

ALTER TABLE [Order] DROP CONSTRAINT FK_ORDER_REFERENCE_CUSTOMER

DELETE FROM [OrderItem] WHERE OrderId = 100;
GO


-- viet trigger khi xoa hoa don cua khach hang Id = 1 thi bao loi va ROLLBACK
-- dua trigger nay len lam Trigger dau tien thuc thi xoa du lieu tren bang Order
CREATE TRIGGER dbo.Trigger_CustomerIdDeleteInOrder
ON [Order]
FOR DELETE 
AS
	DECLARE @DeleteOrderId INT
	
	SELECT @DeleteOrderId = CustomerId
	FROM deleted

	IF (@DeleteOrderId = 1)
	BEGIN
		RAISERROR ('CustomerId = 1 khong xoa duoc', 16, 1);
		-- RAISERROR (message text, severity 16 for user-defined, state)

		ROLLBACK TRANSACTION
	END
GO

EXEC sp_settriggerorder @triggername = 'Trigger_CustomerIdDeleteInOrder', 
	@order = 'First', @stmttype = 'DELETE';

DELETE FROM [Order] WHERE CustomerId = 1;
GO

-- viet trigger khong cho phep cap nhat Phone la Null hay trong Phone co chu cai o bang Supplier
-- neu co thi bao loi va ROLLBACK lai
CREATE TRIGGER dbo.Trigger_SupplierUpdate
ON [Supplier]
FOR UPDATE
AS
	DECLARE @UpdatePhone DECIMAL(12, 2)
	IF UPDATE(Phone)
	BEGIN
		SELECT @UpdatePhone = Phone 
		FROM inserted

		IF @UpdatePhone like '[0-9]*10'
		BEGIN
			RAISERROR('Phone khong Null va khong chua chu cai', 16, 1);
			ROLLBACK TRANSACTION
		END
	END
GO

UPDATE Supplier SET Phone = Null WHERE Id = 1;
GO


-- Cursor
-- viet function input Country, output danh sach cac Id va CompanyName 
CREATE FUNCTION dbo.ufn_ListSupplierByCountry (@CountryDesc NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
	BEGIN
		DECLARE @SupplierList NVARCHAR(MAX) = @CountryDesc + ' list is ';
		DECLARE @Id INT;
		DECLARE @CompanyName NVARCHAR(MAX);

		DECLARE SupplierCursor CURSOR READ_ONLY
		FOR
			SELECT Id, CompanyName
			FROM Supplier
			WHERE LOWER(Country) LIKE '%' + LTRIM(RTRIM(LOWER(@CountryDesc))) + '%'

		OPEN SupplierCursor

		FETCH NEXT FROM SupplierCursor INTO @Id, @CompanyName

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @SupplierList = @SupplierList + LTRIM(STR(@Id)) + ':' + @CompanyName + ';'
			FETCH NEXT FROM SupplierCursor INTO @Id, @CompanyName
		END

		CLOSE SupplierCursor
		DEALLOCATE SupplierCursor

		RETURN @SupplierList
	END
GO

SELECT dbo.ufn_ListSupplierByCountry('USA')
GO


-- transaction
-- viet cac dong lenh cap nhat Quantity cua cac san pham trong abng OrderItem ma co OrderId duoc dat tu khach hang USA
-- Quantity duoc cap nhat bang cach input vao mot @DFactor sau do Quantity = Quantity/ @DFactor
CREATE VIEW uvw_OrderItemDistinct
AS
	SELECT OrI.OrderId
	FROM [OrderItem] OrI
	INNER JOIN [Order] Ord ON Ord.Id = OrI.OrderId
	INNER JOIN [Customer] Cus ON Ord.CustomerId = Cus.Id
	WHERE Cus.Country LIKE '%USA%'
GO

BEGIN TRY
	BEGIN TRANSACTION UpdateQuantityTrans
		SET NOCOUNT ON;
		DECLARE @NumOfUpdateRecords INT = 0;
		DECLARE @NumOfUpdate INT = 0;
		DECLARE @DFactor INT = 2;

		UPDATE OrI SET Quantity = Quantity/2
		FROM [OrderItem] OrI
		INNER JOIN [Order] Ord ON OrI.OrderId = Ord.Id
		INNER JOIN [Customer] Cus ON Ord.CustomerID = Cus.Id
		WHERE Cus.Country LIKE '%USA%'

		SET @NumOfUpdate = @@ROWCOUNT
		PRINT 'cap nhat thanh cong ' + LTRIM(STR(@NumOfUpdate)) + ' dang trong bang OrderItem'
		SET @NumOfUpdateRecords = 
		(
			SELECT COUNT(DISTINCT OrderId)
			FROM uvw_OrderItemDistinct
		)
		PRINT 'cap nhat thanh cong ' + LTRIM(STR(@NumOfUpdateRecords)) + ' hoa don trong bang OrderItem'
	COMMIT TRANSACTION UpdateQuantityTrans
END TRY

BEGIN CATCH
	ROLLBACK TRAN UpdateQuantityTrans
	PRINT 'Cap nhat that bai'
	PRINT ERROR_MESSAGE();
END CATCH


-- temp table
-- viet transaction input la hai quoc gia, output quoc gia co so san pham cung cap nhieu hon
-- cho biet so luong san pham cung cap cua moi quoc gia
BEGIN TRY
	BEGIN TRANSACTION CompareTwoCountryTrans
		SET NOCOUNT ON;
		DECLARE @Country1 NVARCHAR
		DECLARE @Country2 NVARCHAR

		SET @Country1 = 'USA'
		SET @Country2 = 'Germany'

		-- create physical table
		CREATE TABLE #ProductInfo1(SupplierId INT, ProductName NVARCHAR, UnitPrice INT, Package INT)

		-- create a table variable
		DECLARE @ProductInfo2 TABLE(SupplierId INT, ProductName NVARCHAR, UnitPrice INT, Package INt)

		INSERT INTO #ProductInfo1
		SELECT SupplierId, ProductName, UnitPrice, Package
		FROM Product Pro
		LEFT JOIN Supplier Sup ON Sup.Id = Pro.SupplierId
		WHERE @Country1 = Sup.Country
		GROUP BY SupplierId, ProductName, UnitPrice, Package;

		INSERT INTO @ProductInfo2
		SELECT SupplierId, ProductName, UnitPrice, Package
		FROM Product Pro
		LEFT JOIN Supplier Sup ON Sup.Id = Pro.SupplierId
		WHERE @Country1 = Sup.Country
		GROUP BY SupplierId, ProductName, UnitPrice, Package;

		DECLARE @NumSupplier1 INT
		SET @NumSupplier1 = 
		(
			SELECT COUNT(DISTINCT SupplierId) 
			FROM #ProductInfo1
		)
		DECLARE @NumSupplier2 INT
		SET @NumSupplier2 = 
		(
			SELECT COUNT(DISTINCT SupplierId) 
			FROM @ProductInfo2
		)
		PRINT 'quoc gia ' + @Country1 + ': ' + LTRIM(STR(@NumSupplier1)) + ' san pham cung cap'
		PRINT 'quoc gia ' + @Country2 + ': ' + LTRIM(STR(@NumSupplier2)) + ' san pham cung cap'

		PRINT
			CASE
				WHEN @NumSupplier1 = @NumSupplier2
					THEN 'ca hai bang nhau'
				WHEN @NumSupplier1 < @NumSupplier2
					THEN @Country1 + ' it hon ' + @Country2
				ELSE @Country1 + ' nhieu hon ' + @Country2
			END

		DROP TABLE #ProductInfo1
	COMMIT TRANSACTION CompareTwoCOuntryTrans
END TRY
BEGIN CATCH
	ROLLBACK TRAN CompareTwoCountryTrans
	PRINT 'co loi'
	PRINT ERROR_MESSAGE
END CATCH
