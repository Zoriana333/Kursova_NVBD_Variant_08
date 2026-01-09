/* =========================================================
   DW DATABASE
   ========================================================= */
IF DB_ID('Kursova_NVBD_V8_DW') IS NOT NULL
BEGIN
    ALTER DATABASE Kursova_NVBD_V8_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Kursova_NVBD_V8_DW;
END
GO

CREATE DATABASE Kursova_NVBD_V8_DW;
GO
USE Kursova_NVBD_V8_DW;
GO

/* =========================================================
   DIMENSIONS
   ========================================================= */

-- Time Dimension (ключ - int YYYYMMDD)
CREATE TABLE dbo.DimTime(
    TimeKey        INT NOT NULL PRIMARY KEY,  -- 20251214
    [Date]         DATE NOT NULL,
    [Year]         SMALLINT NOT NULL,
    [Quarter]      TINYINT NOT NULL,
    [Month]        TINYINT NOT NULL,
    MonthName      NVARCHAR(20) NOT NULL,
    [Day]          TINYINT NOT NULL,
    DayOfWeek      TINYINT NOT NULL,          -- 1..7
    DayName        NVARCHAR(20) NOT NULL,
    WeekOfYear     TINYINT NOT NULL,
    IsWeekend      BIT NOT NULL
);

-- Product (SCD Type 2)
CREATE TABLE dbo.DimProduct(
    ProductSK      BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProductID      BIGINT NOT NULL,            -- бізнес-ключ з OLTP
    SKU            NVARCHAR(50) NOT NULL,
    ProductName    NVARCHAR(200) NOT NULL,
    Unit           NVARCHAR(20) NOT NULL,
    StandardCost   DECIMAL(18,2) NOT NULL,
    ListPrice      DECIMAL(18,2) NOT NULL,
    IsActive       BIT NOT NULL,

    -- SCD2
    ValidFrom      DATETIME2 NOT NULL,
    ValidTo        DATETIME2 NULL,
    IsCurrent      BIT NOT NULL,

    CONSTRAINT UQ_DimProduct_BK_Current UNIQUE (ProductID, IsCurrent)
);

CREATE TABLE dbo.DimCategory(
    CategorySK     INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID     INT NOT NULL,
    CategoryName   NVARCHAR(100) NOT NULL,
    ParentCategoryID INT NULL
);

CREATE TABLE dbo.DimSupplier(
    SupplierSK     INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID     INT NOT NULL,
    SupplierName   NVARCHAR(200) NOT NULL,
    City           NVARCHAR(80) NULL,
    Country        NVARCHAR(80) NULL,
    IsActive       BIT NOT NULL
);

CREATE TABLE dbo.DimCustomer(
    CustomerSK     INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID     INT NOT NULL,
    CustomerType   CHAR(1) NOT NULL,
    FullName       NVARCHAR(200) NOT NULL,
    City           NVARCHAR(80) NULL,
    Country        NVARCHAR(80) NULL
);

/* =========================================================
   FACTS
   ========================================================= */

-- Fact 1: Sales (тільки OperationType='S')
CREATE TABLE dbo.FactSales(
    SalesID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    TimeKey        INT NOT NULL,
    ProductSK      BIGINT NOT NULL,
    CustomerSK     INT NOT NULL,
    CategorySK     INT NOT NULL,
    SupplierSK     INT NOT NULL,

    QtySold        DECIMAL(18,3) NOT NULL,
    SalesAmount    DECIMAL(18,2) NOT NULL,

    OperationID    BIGINT NOT NULL, -- degenerate key для drill-through

    CONSTRAINT FK_FactSales_Time     FOREIGN KEY (TimeKey)    REFERENCES dbo.DimTime(TimeKey),
    CONSTRAINT FK_FactSales_Product  FOREIGN KEY (ProductSK)  REFERENCES dbo.DimProduct(ProductSK),
    CONSTRAINT FK_FactSales_Cust     FOREIGN KEY (CustomerSK) REFERENCES dbo.DimCustomer(CustomerSK),
    CONSTRAINT FK_FactSales_Cat      FOREIGN KEY (CategorySK) REFERENCES dbo.DimCategory(CategorySK),
    CONSTRAINT FK_FactSales_Supp     FOREIGN KEY (SupplierSK) REFERENCES dbo.DimSupplier(SupplierSK)
);

-- Fact 2: Inventory Operations (I/S/W всі типи)
CREATE TABLE dbo.FactInventoryOps(
    InvFactID      BIGINT IDENTITY(1,1) PRIMARY KEY,
    TimeKey        INT NOT NULL,
    ProductSK      BIGINT NOT NULL,
    CategorySK     INT NOT NULL,
    SupplierSK     INT NULL,
    CustomerSK     INT NULL,

    OperationType  CHAR(1) NOT NULL,  -- I/S/W
    Qty            DECIMAL(18,3) NOT NULL,
    Amount         DECIMAL(18,2) NOT NULL,

    OperationID    BIGINT NOT NULL,

    CONSTRAINT FK_FactInv_Time     FOREIGN KEY (TimeKey)    REFERENCES dbo.DimTime(TimeKey),
    CONSTRAINT FK_FactInv_Product  FOREIGN KEY (ProductSK)  REFERENCES dbo.DimProduct(ProductSK),
    CONSTRAINT FK_FactInv_Cat      FOREIGN KEY (CategorySK) REFERENCES dbo.DimCategory(CategorySK),
    CONSTRAINT FK_FactInv_Supp     FOREIGN KEY (SupplierSK) REFERENCES dbo.DimSupplier(SupplierSK),
    CONSTRAINT FK_FactInv_Cust     FOREIGN KEY (CustomerSK) REFERENCES dbo.DimCustomer(CustomerSK)
);

-- ETL Log (для звіту/скрінів “контроль якості ETL”)
CREATE TABLE dbo.ETL_RunLog(
    RunID          BIGINT IDENTITY(1,1) PRIMARY KEY,
    PackageName    NVARCHAR(200) NOT NULL,
    StartTime      DATETIME2 NOT NULL,
    EndTime        DATETIME2 NULL,
    Status         NVARCHAR(30) NOT NULL,   -- Started/Success/Failed
    RowsInserted   BIGINT NULL,
    ErrorMessage   NVARCHAR(4000) NULL
);
GO

/* Індекси DW (мінімально потрібні) */
CREATE INDEX IX_DimProduct_BK ON dbo.DimProduct(ProductID, IsCurrent) INCLUDE (ProductSK);
CREATE INDEX IX_DimCustomer_BK ON dbo.DimCustomer(CustomerID) INCLUDE (CustomerSK);
CREATE INDEX IX_DimSupplier_BK ON dbo.DimSupplier(SupplierID) INCLUDE (SupplierSK);
CREATE INDEX IX_DimCategory_BK ON dbo.DimCategory(CategoryID) INCLUDE (CategorySK);

CREATE INDEX IX_FactSales_Time ON dbo.FactSales(TimeKey);
CREATE INDEX IX_FactInv_Time ON dbo.FactInventoryOps(TimeKey);
GO
