SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
'*******************************************************************************************************'
' Name: GetBestTicketsForTargetSum.sql
' Description : Purpose: Find the best combination of tickets that sum up to the target sum
'*******************************************************************************************************'

CREATE OR ALTER PROCEDURE [dbo].[GetBestTicketsForTargetSum]
      @TargetSum INT,
    @Pledgee VARCHAR(50) = NULL,
    @PriorityTicketType VARCHAR(50) = 'AFS',
    @Debug BIT = 0,
    @PrioritizePledgeeSum INT = 0 -- 0: minimize total amount, 1: prioritize pledgee sum, 2: use only pledgee's tickets
AS
BEGIN
    SET NOCOUNT ON

    -- Create a temporary table for logging
    IF OBJECT_ID('tempdb..#DebugLog') IS NOT NULL
        DROP TABLE #DebugLog

    CREATE TABLE #DebugLog (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        TargetSum INT,
        CurrentSum INT,
        SelectedIDs VARCHAR(MAX),
        LastID INT,
        Timestamp DATETIME DEFAULT GETDATE()
    )

    DECLARE @BestSum INT = NULL
    DECLARE @BestCombination VARCHAR(MAX) = NULL
    DECLARE @BestPledgeeSum INT = NULL
    DECLARE @BestSmallestTicketNumber VARCHAR(50) = NULL

    -- First attempt: Use priority ticket type only
    EXEC GetBestTicketsRecursive
        @TargetSum = @TargetSum,
        @CurrentSum = 0,
        @SelectedIDs = '',
        @LastID = 0,
        @Pledgee = @Pledgee,
        @PriorityTicketType = @PriorityTicketType,
        @IncludeAllTypes = 0, -- Only priority ticket type
        @PledgeeSum = 0,
        @SmallestTicketNumber = NULL,
        @BestSum = @BestSum OUTPUT,
        @BestCombination = @BestCombination OUTPUT,
        @BestPledgeeSum = @BestPledgeeSum OUTPUT,
        @BestSmallestTicketNumber = @BestSmallestTicketNumber OUTPUT,
        @PrioritizePledgeeSum = @PrioritizePledgeeSum

    -- If the target sum is not met, include other ticket types
    IF @BestSum IS NULL OR @BestSum < @TargetSum
    BEGIN
        -- Reset the variables
        SET @BestSum = NULL
        SET @BestCombination = NULL
        SET @BestPledgeeSum = NULL
        SET @BestSmallestTicketNumber = NULL

        -- Second attempt: Include all ticket types
        EXEC GetBestTicketsRecursive
            @TargetSum = @TargetSum,
            @CurrentSum = 0,
            @SelectedIDs = '',
            @LastID = 0,
            @Pledgee = @Pledgee,
            @PriorityTicketType = @PriorityTicketType,
            @IncludeAllTypes = 1, -- Include all ticket types
            @PledgeeSum = 0,
            @SmallestTicketNumber = NULL,
            @BestSum = @BestSum OUTPUT,
            @BestCombination = @BestCombination OUTPUT,
            @BestPledgeeSum = @BestPledgeeSum OUTPUT,
            @BestSmallestTicketNumber = @BestSmallestTicketNumber OUTPUT,
            @PrioritizePledgeeSum = @PrioritizePledgeeSum
    END

    -- Return the best combination
    SELECT
        BestSum = @BestSum,
        BestCombination = @BestCombination

    -- Print out 'Ticket pledge details'
    PRINT 'Ticket pledge details'

    SELECT *
    FROM Tickets INNER JOIN dbo.SplitString(@BestCombination, ',') AS Split ON Tickets.Ticket = Split.Value

    -- Optionally, return the debug log
    IF @Debug = 1
        SELECT * FROM #DebugLog ORDER BY LogID
END
GO