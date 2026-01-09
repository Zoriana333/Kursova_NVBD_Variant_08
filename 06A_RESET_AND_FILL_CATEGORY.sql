USE Kursova_NVBD_V8_OLTP;
GO
SET NOCOUNT ON;

-- 0) Очистка
DELETE FROM dbo.InventoryOperationLine;
DELETE FROM dbo.InventoryOperation;
DELETE FROM dbo.Payment;
DELETE FROM dbo.SupplierDocument;
DELETE FROM dbo.Product;
DELETE FROM dbo.Customer;
DELETE FROM dbo.Supplier;
DELETE FROM dbo.Category;
GO

-- 0.1) ВАЖЛИВО: скидаємо identity, щоб CategoryID знову стартував з 1
DBCC CHECKIDENT ('dbo.Category', RESEED, 0);
GO

-- 1) 30 батьківських категорій (ParentCategoryID = NULL)
;WITH N AS (
    SELECT TOP (30) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT dbo.Category(CategoryName, ParentCategoryID)
SELECT CONCAT(N'Категорія ', n), NULL
FROM N;
GO

-- 2) 270 дочірніх: ParentCategoryID беремо з реально існуючих батьків
;WITH N AS (
    SELECT TOP (270) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
),
Parents AS (
    SELECT CategoryID
    FROM dbo.Category
    WHERE ParentCategoryID IS NULL
)
INSERT dbo.Category(CategoryName, ParentCategoryID)
SELECT
    CONCAT(N'Категорія ', n + 30),
    (SELECT TOP 1 CategoryID FROM Parents ORDER BY NEWID())
FROM N;
GO

-- Контроль
SELECT
    COUNT(*) AS CategoryCnt,
    SUM(CASE WHEN ParentCategoryID IS NULL THEN 1 ELSE 0 END) AS RootCnt,
    SUM(CASE WHEN ParentCategoryID IS NOT NULL THEN 1 ELSE 0 END) AS ChildCnt,
    MIN(CategoryID) AS MinID,
    MAX(CategoryID) AS MaxID
FROM dbo.Category;
GO
