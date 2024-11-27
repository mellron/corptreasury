SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE OR ALTER PROCEDURE [dbo].[GetBestTicketsForTargetSum]
    @TargetSum INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Create a temporary table for logging
    IF OBJECT_ID('tempdb..#DebugLog') IS NOT NULL
        DROP TABLE #DebugLog;

    CREATE TABLE #DebugLog (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        TargetSum INT,
        CurrentSum INT,
        SelectedIDs VARCHAR(MAX),
        LastID INT,
        Timestamp DATETIME DEFAULT GETDATE()
    );

    DECLARE @BestSum INT = NULL;
    DECLARE @BestCombination VARCHAR(MAX) = NULL;

    EXEC GetBestTicketsRecursive
        @TargetSum = @TargetSum,
        @CurrentSum = 0,
        @SelectedIDs = '',
        @LastID = 0,
        @BestSum = @BestSum OUTPUT,
        @BestCombination = @BestCombination OUTPUT;

    -- Return the best combination
    SELECT
        BestSum = @BestSum,
        BestCombination = @BestCombination;

    -- Optionally, return the debug log
    SELECT * FROM #DebugLog ORDER BY LogID;
END
GO
