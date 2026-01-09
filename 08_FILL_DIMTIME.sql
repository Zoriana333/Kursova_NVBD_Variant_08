USE Kursova_NVBD_V8_DW;
GO
SET NOCOUNT ON;

DECLARE @StartDate DATE = DATEADD(YEAR, -5, CAST(GETDATE() AS DATE));
DECLARE @EndDate   DATE = CAST(GETDATE() AS DATE);

;WITH D AS (
    SELECT @StartDate AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d) FROM D WHERE d < @EndDate
)
INSERT dbo.DimTime(TimeKey, [Date], [Year], [Quarter], [Month], MonthName, [Day], DayOfWeek, DayName, WeekOfYear, IsWeekend)
SELECT
    CONVERT(INT, FORMAT(d, 'yyyyMMdd')) AS TimeKey,
    d,
    DATEPART(YEAR, d),
    DATEPART(QUARTER, d),
    DATEPART(MONTH, d),
    DATENAME(MONTH, d),
    DATEPART(DAY, d),
    DATEPART(WEEKDAY, d),
    DATENAME(WEEKDAY, d),
    DATEPART(ISO_WEEK, d),
    CASE WHEN DATENAME(WEEKDAY, d) IN (N'Saturday', N'Sunday', N'субота', N'неділя') THEN 1 ELSE 0 END
FROM D
OPTION (MAXRECURSION 0);
GO

SELECT COUNT(*) AS DimTimeRows, MIN([Date]) AS MinDate, MAX([Date]) AS MaxDate
FROM dbo.DimTime;
GO

BACKUP DATABASE Kursova_NVBD_V8_OLTP
TO DISK = 'D:\Kursova_NVBD_V8_OLTP.bak'
WITH INIT, COMPRESSION;
