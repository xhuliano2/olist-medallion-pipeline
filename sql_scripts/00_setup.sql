/*  00_setup.sql
   Creates the database, the bronze / silver / gold schemas,
   and the partition function + scheme used to partition the
   orders table by date. */

-- 1. Create the database
CREATE DATABASE OlistEcommerce;
GO

USE OlistEcommerce;
GO

-- 2. Create the three Medallion schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO

/* 
   3. Partitioning
   SQL Server partitions on one column, so we partition the
   orders table on order_purchase_timestamp, one boundary per
   month. The data runs from Sep 2016 to Oct 2018, so we build
   a boundary date for each month in that range with a small
   loop, then create the partition function from that list.
    */
DECLARE @StartDate   DATE = '2016-09-01';
DECLARE @EndDate     DATE = '2018-11-01';
DECLARE @CurrentDate DATE = @StartDate;

CREATE TABLE #PartitionDates (BoundaryDate DATE);

WHILE @CurrentDate <= @EndDate
BEGIN
    INSERT INTO #PartitionDates (BoundaryDate) VALUES (@CurrentDate);
    SET @CurrentDate = DATEADD(MONTH, 1, @CurrentDate);
END;

-- turn the boundary dates into one comma-separated list of values
DECLARE @DateList NVARCHAR(MAX);
SELECT @DateList = STRING_AGG('''' + CONVERT(VARCHAR(10), BoundaryDate, 23) + '''', ',')
FROM #PartitionDates;

-- create the partition function from that list
DECLARE @CreatePF NVARCHAR(MAX) =
    'CREATE PARTITION FUNCTION pf_OrderDate (DATETIME) AS RANGE LEFT FOR VALUES (' + @DateList + ');';
EXEC sp_executesql @CreatePF;

-- all partitions go to the PRIMARY filegroup (fine for a local project)
CREATE PARTITION SCHEME ps_OrderDate
AS PARTITION pf_OrderDate
ALL TO ([PRIMARY]);
GO
