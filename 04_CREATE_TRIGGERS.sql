USE Kursova_NVBD_V8_OLTP;
GO

/* 1) Бізнес-правило: Продаж => має бути CustomerID, Прихід => має бути SupplierID */
CREATE OR ALTER TRIGGER dbo.TR_InventoryOperation_ValidateParty
ON dbo.InventoryOperation
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE OperationType='S' AND CustomerID IS NULL)
    BEGIN
        RAISERROR(N'Для операції продажу (S) CustomerID є обов''язковим.', 16, 1);
        ROLLBACK TRANSACTION; RETURN;
    END

    IF EXISTS (SELECT 1 FROM inserted WHERE OperationType='I' AND SupplierID IS NULL)
    BEGIN
        RAISERROR(N'Для операції приходу (I) SupplierID є обов''язковим.', 16, 1);
        ROLLBACK TRANSACTION; RETURN;
    END
END
GO

/* 2) Бізнес-правило: Платіж IN => CustomerID, OUT => SupplierID */
CREATE OR ALTER TRIGGER dbo.TR_Payment_ValidateParty
ON dbo.Payment
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE Direction='I' AND CustomerID IS NULL)
    BEGIN
        RAISERROR(N'Для платежу IN (I) CustomerID є обов''язковим.', 16, 1);
        ROLLBACK TRANSACTION; RETURN;
    END

    IF EXISTS (SELECT 1 FROM inserted WHERE Direction='O' AND SupplierID IS NULL)
    BEGIN
        RAISERROR(N'Для платежу OUT (O) SupplierID є обов''язковим.', 16, 1);
        ROLLBACK TRANSACTION; RETURN;
    END
END
GO
