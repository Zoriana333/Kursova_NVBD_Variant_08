USE Kursova_NVBD_V8_OLTP;
GO
SET NOCOUNT ON;

-- Очистка залежних таблиць (на всяк випадок)
DELETE FROM dbo.InventoryOperationLine;
DELETE FROM dbo.InventoryOperation;
DELETE FROM dbo.Payment;
DELETE FROM dbo.SupplierDocument;
DELETE FROM dbo.Product;

-- Можна НЕ чистити Supplier/Customer, але ми скинемо і заповнимо заново, щоб ID були 1..N
DELETE FROM dbo.Customer;
DELETE FROM dbo.Supplier;
GO

-- Скидаємо identity
DBCC CHECKIDENT ('dbo.Supplier', RESEED, 0);
DBCC CHECKIDENT ('dbo.Customer', RESEED, 0);
DBCC CHECKIDENT ('dbo.Product',  RESEED, 0);
DBCC CHECKIDENT ('dbo.SupplierDocument', RESEED, 0);
DBCC CHECKIDENT ('dbo.InventoryOperation', RESEED, 0);
DBCC CHECKIDENT ('dbo.InventoryOperationLine', RESEED, 0);
DBCC CHECKIDENT ('dbo.Payment', RESEED, 0);
GO

-- Контроль: має бути 0 рядків
SELECT
  (SELECT COUNT(*) FROM dbo.Supplier) AS SupplierCnt,
  (SELECT COUNT(*) FROM dbo.Customer) AS CustomerCnt,
  (SELECT COUNT(*) FROM dbo.Product) AS ProductCnt;
GO
