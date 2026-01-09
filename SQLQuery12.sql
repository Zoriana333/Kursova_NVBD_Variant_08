USE Kursova_NVBD_V8_DW;
SELECT COUNT(*) AS DimCategoryCnt FROM dbo.DimCategory;
SELECT TOP 5 * FROM dbo.ETL_RunLog ORDER BY RunID DESC;

SELECT COUNT(*) AS DimSupplierCnt FROM dbo.DimSupplier;
SELECT TOP 5 * FROM dbo.DimSupplier;

SELECT COUNT(*) AS DimCustomerCnt FROM dbo.DimCustomer;

DELETE FROM dbo.DimProduct;
SELECT 
  SUM(CASE WHEN IsCurrent=1 THEN 1 ELSE 0 END) AS CurrentRows,
  SUM(CASE WHEN IsCurrent=0 THEN 1 ELSE 0 END) AS HistoryRows
FROM dbo.DimProduct;

SELECT TOP 5 * 
FROM dbo.DimProduct
ORDER BY ProductSK DESC;

USE Kursova_NVBD_V8_DW;

SELECT TOP 1 ProductID, ListPrice
FROM dbo.DimProduct
WHERE IsCurrent = 1
ORDER BY NEWID();

USE Kursova_NVBD_V8_OLTP;

UPDATE dbo.Product
SET ListPrice = ListPrice + 10
WHERE ProductID = 15127;

SELECT ProductID, ListPrice
FROM dbo.Product
WHERE ProductID = 15127;

USE Kursova_NVBD_V8_DW;

SELECT ProductID, ListPrice, ValidFrom, ValidTo, IsCurrent
FROM dbo.DimProduct
WHERE ProductID = 15127
ORDER BY ValidFrom DESC;

USE Kursova_NVBD_V8_DW;
SELECT TOP 5 * FROM dbo.ETL_RunLog ORDER BY RunID DESC;


USE Kursova_NVBD_V8_DW;

-- 1) якщо раптом є дублікати current — залишимо один, решту зробимо 0
;WITH x AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY ValidFrom DESC, ProductSK DESC) AS rn
  FROM dbo.DimProduct
  WHERE IsCurrent = 1
)
UPDATE x
SET IsCurrent = 0, ValidTo = ISNULL(ValidTo, SYSDATETIME())
WHERE rn > 1;

USE Kursova_NVBD_V8_DW;
SELECT COUNT(*) AS FactInventoryOpsCnt
FROM dbo.FactInventoryOps;

SELECT
  SUM(CASE WHEN TimeKey     IS NULL THEN 1 ELSE 0 END) AS NullTimeKey,
  SUM(CASE WHEN ProductSK   IS NULL THEN 1 ELSE 0 END) AS NullProductSK,
  SUM(CASE WHEN CategorySK  IS NULL THEN 1 ELSE 0 END) AS NullCategorySK,
  SUM(CASE WHEN SupplierSK  IS NULL THEN 1 ELSE 0 END) AS NullSupplierSK,
  SUM(CASE WHEN CustomerSK  IS NULL THEN 1 ELSE 0 END) AS NullCustomerSK
FROM dbo.FactInventoryOps;

SELECT TOP (10) f.*
FROM dbo.FactInventoryOps f
LEFT JOIN dbo.DimProduct  dp ON dp.ProductSK  = f.ProductSK
LEFT JOIN dbo.DimCategory dc ON dc.CategorySK = f.CategorySK
LEFT JOIN dbo.DimSupplier ds ON ds.SupplierSK = f.SupplierSK
LEFT JOIN dbo.DimCustomer du ON du.CustomerSK = f.CustomerSK
LEFT JOIN dbo.DimTime     dt ON dt.TimeKey    = f.TimeKey
WHERE dp.ProductSK IS NULL
   OR dc.CategorySK IS NULL
   OR ds.SupplierSK IS NULL
   OR (f.CustomerSK IS NOT NULL AND du.CustomerSK IS NULL)
   OR dt.TimeKey IS NULL;

SELECT IsCurrent, COUNT(*) 
FROM dbo.DimProduct
GROUP BY IsCurrent;

SELECT DB_NAME() AS CurrentDB;

SELECT COUNT(*) AS DimSupplierCnt
FROM dbo.DimSupplier;

SELECT
  SUM(CASE WHEN IsCurrent = 1 THEN 1 ELSE 0 END) AS CurrentRows,
  SUM(CASE WHEN IsCurrent = 0 THEN 1 ELSE 0 END) AS HistoryRows,
  SUM(CASE WHEN IsCurrent IS NULL THEN 1 ELSE 0 END) AS NullIsCurrent
FROM dbo.DimProduct;

USE Kursova_NVBD_V8_DW;
SELECT TOP 5 *
FROM dbo.ETL_RunLog
ORDER BY RunID DESC;

SELECT
    r.session_id,
    s.host_name,
    s.program_name,
    s.login_name,
    r.status,
    r.command,
    r.wait_type,
    r.wait_time,
    r.blocking_session_id,
    DB_NAME(r.database_id) AS dbname,
    SUBSTRING(t.text, (r.statement_start_offset/2)+1,
        ((CASE r.statement_end_offset WHEN -1 THEN DATALENGTH(t.text)
          ELSE r.statement_end_offset END - r.statement_start_offset)/2)+1) AS running_statement
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.database_id = DB_ID('Kursova_NVBD_V8_DW')
  AND r.session_id <> @@SPID
ORDER BY r.wait_time DESC;

USE Kursova_NVBD_V8_OLTP;
SELECT DISTINCT OperationType
FROM dbo.InventoryOperation;
SELECT MAX(OperationDate) AS MaxOpDate
FROM dbo.InventoryOperation;

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ETL_ErrorRows';

USE Kursova_NVBD_V8_DW;
SELECT TOP 50 *
FROM dbo.ETL_ErrorRows
ORDER BY ErrorID DESC;

SELECT TOP 20 *
FROM dbo.FactSales
ORDER BY SalesID DESC;

USE Kursova_NVBD_V8_OLTP;
SELECT COUNT(*) AS CntAll, MAX(OperationDate) AS MaxOpDate
FROM dbo.InventoryOperation;

DECLARE @LastLoadTime datetime2 = '19000101'; -- тимчасово постав 1900 для тесту
SELECT COUNT(*) AS CntAfter
FROM dbo.InventoryOperation
WHERE OperationDate > @LastLoadTime;

USE Kursova_NVBD_V8_DW;
SELECT COUNT(*) AS DimProductCnt
FROM dbo.DimProduct;

SELECT TOP 10 ProductID
FROM dbo.DimProduct
ORDER BY ProductID;

USE Kursova_NVBD_V8_OLTP;
SELECT TOP 10 ProductID
FROM dbo.Product
ORDER BY ProductID;

USE Kursova_NVBD_V8_DW;
SELECT
  (SELECT COUNT(*) FROM dbo.DimProduct)  AS DimProduct,
  (SELECT COUNT(*) FROM dbo.DimCategory) AS DimCategory,
  (SELECT COUNT(*) FROM dbo.DimCustomer) AS DimCustomer,
  (SELECT COUNT(*) FROM dbo.DimSupplier) AS DimSupplier,
  (SELECT COUNT(*) FROM dbo.DimTime)     AS DimTime;


SELECT COUNT(*) FROM dbo.FactSales;

SELECT SUSER_SNAME();