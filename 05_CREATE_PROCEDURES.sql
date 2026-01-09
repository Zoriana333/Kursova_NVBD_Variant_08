USE Kursova_NVBD_V8_OLTP;
GO

/* Залишки по товарах (для звіту "наявність") */
CREATE OR ALTER PROCEDURE dbo.usp_GetStock
    @CategoryID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.ProductID,
        p.SKU,
        p.ProductName,
        c.CategoryName,
        SUM(CASE WHEN o.OperationType='I' THEN l.Quantity
                 WHEN o.OperationType IN ('S','W') THEN -l.Quantity
                 ELSE 0 END) AS StockQty
    FROM dbo.Product p
    JOIN dbo.Category c ON c.CategoryID = p.CategoryID
    LEFT JOIN dbo.InventoryOperationLine l ON l.ProductID = p.ProductID
    LEFT JOIN dbo.InventoryOperation o ON o.OperationID = l.OperationID
    WHERE @CategoryID IS NULL OR p.CategoryID = @CategoryID
    GROUP BY p.ProductID, p.SKU, p.ProductName, c.CategoryName
    ORDER BY StockQty DESC;
END
GO

/* Обіг товарів за період (для звіту "обіг за період") */
CREATE OR ALTER PROCEDURE dbo.usp_GetTurnover
    @DateFrom DATETIME2,
    @DateTo   DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.ProductID,
        p.SKU,
        p.ProductName,
        SUM(CASE WHEN o.OperationType='I' THEN l.Quantity ELSE 0 END) AS QtyIn,
        SUM(CASE WHEN o.OperationType IN ('S','W') THEN l.Quantity ELSE 0 END) AS QtyOut,
        SUM(CASE WHEN o.OperationType='S' THEN l.LineAmount ELSE 0 END) AS SalesAmount
    FROM dbo.InventoryOperation o
    JOIN dbo.InventoryOperationLine l ON l.OperationID = o.OperationID
    JOIN dbo.Product p ON p.ProductID = l.ProductID
    WHERE o.OperationDate >= @DateFrom AND o.OperationDate < @DateTo
    GROUP BY p.ProductID, p.SKU, p.ProductName
    ORDER BY SalesAmount DESC;
END
GO
