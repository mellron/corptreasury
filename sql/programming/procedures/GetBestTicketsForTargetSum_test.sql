CREATE OR ALTER PROCEDURE [dbo].[GetBestTicketsForTargetSum_test]
    @TargetSum INT,
    @PriorityTicketType VARCHAR(50) = 'AFS',
    @Debug BIT = 0
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
    DECLARE @BestAverageAvailablePercent DECIMAL(10,2) = NULL;
    DECLARE @BestTicketCount INT = NULL;
    DECLARE @BestSmallestTicketNumber VARCHAR(50) = NULL;

    -- First attempt: Use priority ticket type only
    EXEC GetBestTicketsRecursive_test
        @TargetSum = @TargetSum,
        @CurrentSum = 0,
        @SelectedIDs = '',
        @LastID = 0,
        @PriorityTicketType = @PriorityTicketType,
        @IncludeAllTypes = 0, -- Only priority ticket type
        @AvailablePercentSum = 0,
        @TicketCount = 0,
        @SmallestTicketNumber = NULL,
        @BestSum = @BestSum OUTPUT,
        @BestCombination = @BestCombination OUTPUT,
        @BestAverageAvailablePercent = @BestAverageAvailablePercent OUTPUT,
        @BestTicketCount = @BestTicketCount OUTPUT,
        @BestSmallestTicketNumber = @BestSmallestTicketNumber OUTPUT;

    -- If the target sum is not met, include other ticket types
    IF @BestSum IS NULL OR @BestSum < @TargetSum
    BEGIN
        -- Reset the variables
        SET @BestSum = NULL;
        SET @BestCombination = NULL;
        SET @BestAverageAvailablePercent = NULL;
        SET @BestTicketCount = NULL;
        SET @BestSmallestTicketNumber = NULL;

        -- Second attempt: Include all ticket types
        EXEC GetBestTicketsRecursive_test
            @TargetSum = @TargetSum,
            @CurrentSum = 0,
            @SelectedIDs = '',
            @LastID = 0,
            @PriorityTicketType = @PriorityTicketType,
            @IncludeAllTypes = 1, -- Include all ticket types
            @AvailablePercentSum = 0,
            @TicketCount = 0,
            @SmallestTicketNumber = NULL,
            @BestSum = @BestSum OUTPUT,
            @BestCombination = @BestCombination OUTPUT,
            @BestAverageAvailablePercent = @BestAverageAvailablePercent OUTPUT,
            @BestTicketCount = @BestTicketCount OUTPUT,
            @BestSmallestTicketNumber = @BestSmallestTicketNumber OUTPUT;
    END

    -- Return the best combination
    SELECT
        BestSum = @BestSum,
        BestCombination = @BestCombination,        
        (SELECT COUNT(*) FROM dbo.SplitString(@BestCombination, ',')) AS [Number of tickets used],
        (SELECT SUM(Available_Percent) FROM Tickets_VW WHERE Ticket IN (SELECT Value FROM dbo.SplitString(@BestCombination, ','))) AS [Total of percentages used],
        BestAverageAvailablePercent = @BestAverageAvailablePercent

    -- Print out 'Ticket pledge details'
    PRINT 'Ticket pledge details';

    SELECT *
    FROM Tickets_VW INNER JOIN dbo.SplitString(@BestCombination, ',') AS Split ON Tickets_VW.Ticket = Split.Value;

    -- Optionally, return the debug log
    IF @Debug = 1
        SELECT * FROM #DebugLog ORDER BY LogID;
END
GO
