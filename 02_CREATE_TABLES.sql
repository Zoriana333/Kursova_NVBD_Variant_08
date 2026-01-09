USE Kursova_NVBD_V8_OLTP;
GO

/* =========================================================
   1) ÄÎÂ²ÄÍÈÊÈ
   ========================================================= */

IF OBJECT_ID('dbo.InventoryOperationLine', 'U') IS NOT NULL DROP TABLE dbo.InventoryOperationLine;
IF OBJECT_ID('dbo.InventoryOperation', 'U')     IS NOT NULL DROP TABLE dbo.InventoryOperation;
IF OBJECT_ID('dbo.Payment', 'U')                IS NOT NULL DROP TABLE dbo.Payment;
IF OBJECT_ID('dbo.SupplierDocument', 'U')       IS NOT NULL DROP TABLE dbo.SupplierDocument;
IF OBJECT_ID('dbo.Product', 'U')                IS NOT NULL DROP TABLE dbo.Product;
IF OBJECT_ID('dbo.Customer', 'U')               IS NOT NULL DROP TABLE dbo.Customer;
IF OBJECT_ID('dbo.Supplier', 'U')               IS NOT NULL DROP TABLE dbo.Supplier;
IF OBJECT_ID('dbo.Category', 'U')               IS NOT NULL DROP TABLE dbo.Category;
GO

CREATE TABLE dbo.Category(
    CategoryID        INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName      NVARCHAR(100) NOT NULL,
    ParentCategoryID  INT NULL,
    CONSTRAINT UQ_Category_CategoryName UNIQUE (CategoryName),
    CONSTRAINT FK_Category_Parent FOREIGN KEY (ParentCategoryID) REFERENCES dbo.Category(CategoryID)
);

CREATE TABLE dbo.Supplier(
    SupplierID     INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName   NVARCHAR(200) NOT NULL,
    TaxCode        NVARCHAR(20) NULL,
    Phone          NVARCHAR(30) NULL,
    Email          NVARCHAR(120) NULL,
    City           NVARCHAR(80) NULL,
    Country        NVARCHAR(80) NULL,
    IsActive       BIT NOT NULL CONSTRAINT DF_Supplier_IsActive DEFAULT(1),
    CreatedAt      DATETIME2 NOT NULL CONSTRAINT DF_Supplier_CreatedAt DEFAULT(SYSDATETIME()),
    CONSTRAINT UQ_Supplier_Name UNIQUE (SupplierName),
    CONSTRAINT UQ_Supplier_TaxCode UNIQUE (TaxCode)
);

CREATE TABLE dbo.Customer(
    CustomerID     INT IDENTITY(1,1) PRIMARY KEY,
    CustomerType   CHAR(1) NOT NULL,  -- 'P' ô³ç. îñîáà, 'B' þð. îñîáà
    FullName       NVARCHAR(200) NOT NULL,
    Phone          NVARCHAR(30) NULL,
    Email          NVARCHAR(120) NULL,
    City           NVARCHAR(80) NULL,
    Country        NVARCHAR(80) NULL,
    CreatedAt      DATETIME2 NOT NULL CONSTRAINT DF_Customer_CreatedAt DEFAULT(SYSDATETIME()),
    CONSTRAINT CK_Customer_Type CHECK (CustomerType IN ('P','B'))
);

CREATE TABLE dbo.Product(
    ProductID      BIGINT IDENTITY(1,1) PRIMARY KEY,
    SKU            NVARCHAR(50) NOT NULL,
    ProductName    NVARCHAR(200) NOT NULL,
    CategoryID     INT NOT NULL,
    SupplierID     INT NOT NULL,
    Unit           NVARCHAR(20) NOT NULL CONSTRAINT DF_Product_Unit DEFAULT('pcs'),
    StandardCost   DECIMAL(18,2) NOT NULL,
    ListPrice      DECIMAL(18,2) NOT NULL,
    IsActive       BIT NOT NULL CONSTRAINT DF_Product_IsActive DEFAULT(1),
    CreatedAt      DATETIME2 NOT NULL CONSTRAINT DF_Product_CreatedAt DEFAULT(SYSDATETIME()),
    CONSTRAINT UQ_Product_SKU UNIQUE (SKU),
    CONSTRAINT CK_Product_Cost CHECK (StandardCost >= 0),
    CONSTRAINT CK_Product_Price CHECK (ListPrice >= 0),
    CONSTRAINT FK_Product_Category FOREIGN KEY (CategoryID) REFERENCES dbo.Category(CategoryID),
    CONSTRAINT FK_Product_Supplier FOREIGN KEY (SupplierID) REFERENCES dbo.Supplier(SupplierID)
);

/* =========================================================
   2) ÄÎÊÓÌÅÍÒÈ ÏÎÑÒÀ×ÀËÜÍÈÊ²Â
   ========================================================= */
CREATE TABLE dbo.SupplierDocument(
    SupplierDocumentID BIGINT IDENTITY(1,1) PRIMARY KEY,
    SupplierID         INT NOT NULL,
    DocumentType       NVARCHAR(50) NOT NULL,
    DocumentNumber     NVARCHAR(50) NOT NULL,
    IssueDate          DATE NOT NULL,
    ValidTo            DATE NULL,
    Notes              NVARCHAR(200) NULL,
    CONSTRAINT FK_SupplierDocument_Supplier FOREIGN KEY (SupplierID) REFERENCES dbo.Supplier(SupplierID),
    CONSTRAINT CK_SupplierDocument_ValidTo CHECK (ValidTo IS NULL OR ValidTo >= IssueDate)
);

/* =========================================================
   3) ÎÏÅÐÀÖ²¯ ÑÊËÀÄÓ (ïðèõ³ä/ïðîäàæ/ñïèñàííÿ)
   ========================================================= */
CREATE TABLE dbo.InventoryOperation(
    OperationID    BIGINT IDENTITY(1,1) PRIMARY KEY,
    OperationDate  DATETIME2 NOT NULL,
    OperationType  CHAR(1) NOT NULL, -- 'I' income, 'S' sale, 'W' writeoff
    SupplierID     INT NULL,
    CustomerID     INT NULL,
    Warehouse      NVARCHAR(80) NOT NULL CONSTRAINT DF_InventoryOperation_Warehouse DEFAULT('MAIN'),
    DocumentNo     NVARCHAR(50) NULL,
    Notes          NVARCHAR(200) NULL,
    CONSTRAINT CK_InventoryOperation_Type CHECK (OperationType IN ('I','S','W')),
    CONSTRAINT FK_InventoryOperation_Supplier FOREIGN KEY (SupplierID) REFERENCES dbo.Supplier(SupplierID),
    CONSTRAINT FK_InventoryOperation_Customer FOREIGN KEY (CustomerID) REFERENCES dbo.Customer(CustomerID)
);

CREATE TABLE dbo.InventoryOperationLine(
    OperationLineID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OperationID     BIGINT NOT NULL,
    ProductID       BIGINT NOT NULL,
    Quantity        DECIMAL(18,3) NOT NULL,
    UnitPrice       DECIMAL(18,2) NOT NULL,
    LineAmount      AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT FK_InvLine_Operation FOREIGN KEY (OperationID) REFERENCES dbo.InventoryOperation(OperationID),
    CONSTRAINT FK_InvLine_Product FOREIGN KEY (ProductID) REFERENCES dbo.Product(ProductID),
    CONSTRAINT CK_InvLine_Qty CHECK (Quantity > 0),
    CONSTRAINT CK_InvLine_Price CHECK (UnitPrice >= 0)
);

/* =========================================================
   4) ÏËÀÒÅÆ²
   ========================================================= */
CREATE TABLE dbo.Payment(
    PaymentID      BIGINT IDENTITY(1,1) PRIMARY KEY,
    PaymentDate    DATETIME2 NOT NULL,
    Direction      CHAR(1) NOT NULL, -- 'I' in (â³ä êë³ºíòà), 'O' out (ïîñòà÷àëüíèêó)
    SupplierID     INT NULL,
    CustomerID     INT NULL,
    Amount         DECIMAL(18,2) NOT NULL,
    Currency       CHAR(3) NOT NULL CONSTRAINT DF_Payment_Currency DEFAULT('UAH'),
    Method         NVARCHAR(30) NOT NULL CONSTRAINT DF_Payment_Method DEFAULT('Bank'),
    ReferenceNo    NVARCHAR(60) NULL,
    Notes          NVARCHAR(200) NULL,
    CONSTRAINT CK_Payment_Direction CHECK (Direction IN ('I','O')),
    CONSTRAINT CK_Payment_Amount CHECK (Amount > 0),
    CONSTRAINT FK_Payment_Supplier FOREIGN KEY (SupplierID) REFERENCES dbo.Supplier(SupplierID),
    CONSTRAINT FK_Payment_Customer FOREIGN KEY (CustomerID) REFERENCES dbo.Customer(CustomerID)
);
GO

SELECT
  t.name AS TableName
FROM sys.tables t
ORDER BY t.name;