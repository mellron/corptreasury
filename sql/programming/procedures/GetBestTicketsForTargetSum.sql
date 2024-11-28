SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[GetBestTicketsForTargetSum]
    @TargetSum INT,
    @Pledgee VARCHAR(50) = NULL,
    @PriorityTicketType VARCHAR(50) = 'ACH'
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

    -- First attempt: Use priority ticket type only
    EXEC GetBestTicketsRecursive
        @TargetSum = @TargetSum,
        @CurrentSum = 0,
        @SelectedIDs = '',
        @LastID = 0,
        @Pledgee = @Pledgee,
        @PriorityTicketType = @PriorityTicketType,
        @IncludeAllTypes = 0, -- Only priority ticket type
        @BestSum = @BestSum OUTPUT,
        @BestCombination = @BestCombination OUTPUT;

    -- If the target sum is not met, include other ticket types
    IF @BestSum IS NULL OR @BestSum < @TargetSum
    BEGIN
        -- Reset the variables
        SET @BestSum = NULL;
        SET @BestCombination = NULL;

        -- Second attempt: Include all ticket types
        EXEC GetBestTicketsRecursive
            @TargetSum = @TargetSum,
            @CurrentSum = 0,
            @SelectedIDs = '',
            @LastID = 0,
            @Pledgee = @Pledgee,
            @PriorityTicketType = @PriorityTicketType,
            @IncludeAllTypes = 1, -- Include all ticket types
            @BestSum = @BestSum OUTPUT,
            @BestCombination = @BestCombination OUTPUT;
    END

    -- Return the best combination
    SELECT
        BestSum = @BestSum,
        BestCombination = @BestCombination;

    -- Optionally, return the debug log
    SELECT * FROM #DebugLog ORDER BY LogID;
END
GO
