USE Kursova_NVBD_V8_OLTP;
GO
SET NOCOUNT ON;

------------------------------------------------------------
-- 2) Постачальники (2000)
------------------------------------------------------------
;WITH N AS (
    SELECT TOP (2000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.Supplier(SupplierName, TaxCode, Phone, Email, City, Country, IsActive)
SELECT
    CONCAT(N'Постачальник ', n),
    CONCAT('TC', FORMAT(n, '0000000000')),
    CONCAT('+380', RIGHT(CONCAT('000000000', n), 9)),
    CONCAT('supplier', n, '@mail.com'),
    CONCAT(N'Місто ', 1 + (n % 50)),
    N'Україна',
    CASE WHEN n % 20 = 0 THEN 0 ELSE 1 END
FROM N;
GO

------------------------------------------------------------
-- 3) Клієнти (100000)
------------------------------------------------------------
;WITH N AS (
    SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.Customer(CustomerType, FullName, Phone, Email, City, Country)
SELECT
    CASE WHEN n % 5 = 0 THEN 'B' ELSE 'P' END,
    CASE WHEN n % 5 = 0 THEN CONCAT(N'ТОВ "Клієнт ', n, N'"')
         ELSE CONCAT(N'Клієнт ', n) END,
    CONCAT('+380', RIGHT(CONCAT('000000000', n), 9)),
    CONCAT('customer', n, '@mail.com'),
    CONCAT(N'Місто ', 1 + (n % 100)),
    N'Україна'
FROM N;
GO

------------------------------------------------------------
-- 4) Товари (50000) - тепер CategoryID гарантовано існує
------------------------------------------------------------
;WITH N AS (
    SELECT TOP (50000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.Product(SKU, ProductName, CategoryID, SupplierID, Unit, StandardCost, ListPrice, IsActive)
SELECT
    CONCAT('SKU-', FORMAT(n, '000000')),
    CONCAT(N'Товар ', n),
    1 + (ABS(CHECKSUM(NEWID())) % 300),
    1 + (ABS(CHECKSUM(NEWID())) % 2000),
    'pcs',
    CAST(10 + (ABS(CHECKSUM(NEWID())) % 5000) * 1.0 AS DECIMAL(18,2)),
    CAST(12 + (ABS(CHECKSUM(NEWID())) % 6500) * 1.0 AS DECIMAL(18,2)),
    CASE WHEN n % 40 = 0 THEN 0 ELSE 1 END
FROM N;
GO

------------------------------------------------------------
-- 5) Документи постачальників (8000)
------------------------------------------------------------
;WITH N AS (
    SELECT TOP (8000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.SupplierDocument(SupplierID, DocumentType, DocumentNumber, IssueDate, ValidTo, Notes)
SELECT
    1 + (ABS(CHECKSUM(NEWID())) % 2000),
    CASE WHEN n % 3 = 0 THEN 'Contract'
         WHEN n % 3 = 1 THEN 'Invoice'
         ELSE 'Certificate' END,
    CONCAT('DOC-', FORMAT(n, '000000')),
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 1825), CAST(GETDATE() AS date)),
    NULL,
    N'Автогенерація'
FROM N;
GO

------------------------------------------------------------
-- 6) 1 000 000 операцій
------------------------------------------------------------
DECLARE @StartDate DATETIME2 = DATEADD(YEAR, -5, SYSDATETIME());
DECLARE @Days INT = 1825;

;WITH N AS (
    SELECT TOP (1000000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
),
T AS (
    SELECT
      n,
      DATEADD(DAY, (ABS(CHECKSUM(NEWID())) % @Days), @StartDate) AS OperationDate,
      CASE
        WHEN n % 20 = 0 THEN 'W'
        WHEN n % 2 = 0 THEN 'S'
        ELSE 'I'
      END AS OperationType
    FROM N
)
INSERT dbo.InventoryOperation(OperationDate, OperationType, SupplierID, CustomerID, Warehouse, DocumentNo, Notes)
SELECT
    OperationDate,
    OperationType,
    CASE WHEN OperationType='I' THEN 1 + (ABS(CHECKSUM(NEWID())) % 2000) ELSE NULL END,
    CASE WHEN OperationType='S' THEN 1 + (ABS(CHECKSUM(NEWID())) % 100000) ELSE NULL END,
    CASE WHEN n % 3 = 0 THEN 'MAIN' WHEN n % 3 = 1 THEN 'WEST' ELSE 'EAST' END,
    CONCAT('OP-', FORMAT(n,'000000000')),
    N'Автогенерація'
FROM T;
GO

------------------------------------------------------------
-- 7) Рядки операцій (1 000 000)
------------------------------------------------------------
INSERT dbo.InventoryOperationLine(OperationID, ProductID, Quantity, UnitPrice)
SELECT
    o.OperationID,
    1 + (ABS(CHECKSUM(NEWID())) % 50000),
    CAST(1 + (ABS(CHECKSUM(NEWID())) % 20) * 1.0 AS DECIMAL(18,3)),
    CASE
      WHEN o.OperationType='I' THEN CAST(10 + (ABS(CHECKSUM(NEWID())) % 5000) * 1.0 AS DECIMAL(18,2))
      WHEN o.OperationType='S' THEN CAST(12 + (ABS(CHECKSUM(NEWID())) % 6500) * 1.0 AS DECIMAL(18,2))
      ELSE 0
    END
FROM dbo.InventoryOperation o;
GO

------------------------------------------------------------
-- 8) Платежі (300 000)
------------------------------------------------------------
DECLARE @PayStart DATETIME2 = DATEADD(YEAR, -5, SYSDATETIME());
DECLARE @PayDays INT = 1825;

;WITH N AS (
    SELECT TOP (300000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.Payment(PaymentDate, Direction, SupplierID, CustomerID, Amount, Currency, Method, ReferenceNo, Notes)
SELECT
    DATEADD(DAY, (ABS(CHECKSUM(NEWID())) % @PayDays), @PayStart),
    CASE WHEN n % 2 = 0 THEN 'I' ELSE 'O' END,
    CASE WHEN n % 2 = 1 THEN 1 + (ABS(CHECKSUM(NEWID())) % 2000) ELSE NULL END,
    CASE WHEN n % 2 = 0 THEN 1 + (ABS(CHECKSUM(NEWID())) % 100000) ELSE NULL END,
    CAST(100 + (ABS(CHECKSUM(NEWID())) % 200000) * 1.0 AS DECIMAL(18,2)),
    'UAH',
    CASE WHEN n % 3 = 0 THEN 'Bank' WHEN n % 3 = 1 THEN 'Cash' ELSE 'Card' END,
    CONCAT('PAY-', FORMAT(n,'000000000')),
    N'Автогенерація'
FROM N;
GO

------------------------------------------------------------
-- 9) Підрахунки
------------------------------------------------------------
SELECT 'Category' AS [Table], COUNT(*) AS Cnt FROM dbo.Category
UNION ALL SELECT 'Supplier', COUNT(*) FROM dbo.Supplier
UNION ALL SELECT 'Customer', COUNT(*) FROM dbo.Customer
UNION ALL SELECT 'Product', COUNT(*) FROM dbo.Product
UNION ALL SELECT 'SupplierDocument', COUNT(*) FROM dbo.SupplierDocument
UNION ALL SELECT 'InventoryOperation', COUNT(*) FROM dbo.InventoryOperation
UNION ALL SELECT 'InventoryOperationLine', COUNT(*) FROM dbo.InventoryOperationLine
UNION ALL SELECT 'Payment', COUNT(*) FROM dbo.Payment;
GO


SELECT
  MIN(OperationDate) AS MinDate,
  MAX(OperationDate) AS MaxDate
FROM dbo.InventoryOperation;

SELECT
  DATEDIFF(YEAR, MIN(OperationDate), MAX(OperationDate)) AS YearsSpan
FROM dbo.InventoryOperation;

-- перевірка “битих” зв'язків у рядках операцій
SELECT TOP (10) *
FROM dbo.InventoryOperationLine l
LEFT JOIN dbo.InventoryOperation o ON o.OperationID = l.OperationID
WHERE o.OperationID IS NULL;

SELECT TOP (10) *
FROM dbo.InventoryOperationLine l
LEFT JOIN dbo.Product p ON p.ProductID = l.ProductID
WHERE p.ProductID IS NULL;

-- приклад запиту “обіг товарів за період”
DECLARE @d1 datetime2 = DATEADD(MONTH, -1, SYSDATETIME());
DECLARE @d2 datetime2 = SYSDATETIME();

SELECT TOP (10)
  p.ProductName,
  SUM(CASE WHEN o.OperationType='S' THEN l.LineAmount ELSE 0 END) AS SalesAmount
FROM dbo.InventoryOperation o
JOIN dbo.InventoryOperationLine l ON l.OperationID = o.OperationID
JOIN dbo.Product p ON p.ProductID = l.ProductID
WHERE o.OperationDate >= @d1 AND o.OperationDate < @d2
GROUP BY p.ProductName
ORDER BY SalesAmount DESC;


