USE Kursova_NVBD_V8_DW;

CREATE TABLE dbo.ETL_ErrorRows(
    ErrorID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    ErrorDateTime  DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    PackageName    NVARCHAR(200) NOT NULL,
    StepName       NVARCHAR(200) NOT NULL,

    RunID          BIGINT NULL,

    -- бізнес-поля з потоку (мінімум)
    OperationID    BIGINT NULL,
    OperationDate  DATETIME2 NULL,
    OperationType  NVARCHAR(50) NULL,

    ProductID      BIGINT NULL,
    SupplierID     INT NULL,
    CustomerID     INT NULL,
    CategoryID     INT NULL,

    Quantity       DECIMAL(18,4) NULL,
    UnitPrice      DECIMAL(18,4) NULL,
    LineAmount     DECIMAL(18,4) NULL,

    -- технічні поля SSIS помилки (якщо з’являться)
    ErrorCode      INT NULL,
    ErrorColumn    INT NULL,

    ErrorDescription NVARCHAR(4000) NULL
);
