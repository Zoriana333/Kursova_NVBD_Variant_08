USE Kursova_NVBD_V8_OLTP;
GO

-- Product(CategoryID)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Product_CategoryID' AND object_id = OBJECT_ID('dbo.Product')
)
    CREATE INDEX IX_Product_CategoryID ON dbo.Product(CategoryID);
GO

-- Product(SupplierID)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Product_SupplierID' AND object_id = OBJECT_ID('dbo.Product')
)
    CREATE INDEX IX_Product_SupplierID ON dbo.Product(SupplierID);
GO

-- Product(SKU)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Product_SKU' AND object_id = OBJECT_ID('dbo.Product')
)
    CREATE INDEX IX_Product_SKU ON dbo.Product(SKU);
GO

-- InventoryOperation(OperationDate, OperationType)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_InvOp_DateType' AND object_id = OBJECT_ID('dbo.InventoryOperation')
)
    CREATE INDEX IX_InvOp_DateType ON dbo.InventoryOperation(OperationDate, OperationType);
GO

-- InventoryOperationLine(OperationID)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_InvLine_OperationID' AND object_id = OBJECT_ID('dbo.InventoryOperationLine')
)
    CREATE INDEX IX_InvLine_OperationID ON dbo.InventoryOperationLine(OperationID);
GO

-- InventoryOperationLine(ProductID)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_InvLine_ProductID' AND object_id = OBJECT_ID('dbo.InventoryOperationLine')
)
    CREATE INDEX IX_InvLine_ProductID ON dbo.InventoryOperationLine(ProductID);
GO

-- Payment(PaymentDate, Direction)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Payment_DateDir' AND object_id = OBJECT_ID('dbo.Payment')
)
    CREATE INDEX IX_Payment_DateDir ON dbo.Payment(PaymentDate, Direction);
GO

-- SupplierDocument(SupplierID, IssueDate)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_SupplierDoc_Supplier' AND object_id = OBJECT_ID('dbo.SupplierDocument')
)
    CREATE INDEX IX_SupplierDoc_Supplier ON dbo.SupplierDocument(SupplierID, IssueDate);
GO
