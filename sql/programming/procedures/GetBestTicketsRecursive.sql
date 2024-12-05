SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER  PROCEDURE [dbo].[GetBestTicketsRecursive]
    @TargetSum INT,
    @Pledgee VARCHAR(50),
    @CurrentSum INT = 0,
    @SelectedIDs VARCHAR(MAX) = '',
    @LastID INT = 0,
    @PriorityTicketType VARCHAR(50) = 'AFS',
    @IncludeAllTypes BIT = 0,
    @AvailablePercentSum DECIMAL(18,2) = 0,
    @TicketCount INT = 0,
    @SmallestTicketNumber VARCHAR(50) = NULL,
    @BestSum INT = NULL OUTPUT,
    @BestCombination VARCHAR(MAX) = NULL OUTPUT,
    @BestAverageAvailablePercent DECIMAL(18,2) = NULL OUTPUT,
    @BestOverage INT = NULL OUTPUT,
    @BestTicketCount INT = NULL OUTPUT,
    @BestSmallestTicketNumber VARCHAR(50) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Base Case
    IF @CurrentSum >= @TargetSum
    BEGIN
        DECLARE @Overage INT = @CurrentSum - @TargetSum;
        DECLARE @CurrentAverageAvailablePercent DECIMAL(18,2) = @AvailablePercentSum / NULLIF(@TicketCount, 0);

        IF (@BestSum IS NULL) OR
           (@CurrentAverageAvailablePercent > @BestAverageAvailablePercent) OR
           (@CurrentAverageAvailablePercent = @BestAverageAvailablePercent AND @Overage < @BestOverage) OR
           (@CurrentAverageAvailablePercent = @BestAverageAvailablePercent AND @Overage = @BestOverage AND @TicketCount < @BestTicketCount) OR
           (@CurrentAverageAvailablePercent = @BestAverageAvailablePercent AND @Overage = @BestOverage AND @TicketCount = @BestTicketCount AND @SmallestTicketNumber < @BestSmallestTicketNumber)
        BEGIN
            SET @BestSum = @CurrentSum;
            SET @BestCombination = @SelectedIDs;
            SET @BestAverageAvailablePercent = @CurrentAverageAvailablePercent;
            SET @BestOverage = @Overage;
            SET @BestTicketCount = @TicketCount;
            SET @BestSmallestTicketNumber = @SmallestTicketNumber;
        END
        RETURN;
    END

    -- Pruning Logic
    DECLARE @CurrentAvg DECIMAL(18,2) = @AvailablePercentSum / NULLIF(@TicketCount, 0);
    DECLARE @CurrentOverage INT = @CurrentSum - @TargetSum;

    IF @BestAverageAvailablePercent IS NOT NULL AND
       (
           (@CurrentAvg < @BestAverageAvailablePercent) OR
           (@CurrentAvg = @BestAverageAvailablePercent AND @CurrentOverage > @BestOverage) OR
           (@CurrentAvg = @BestAverageAvailablePercent AND @CurrentOverage = @BestOverage AND @TicketCount > @BestTicketCount) OR
           (@CurrentAvg = @BestAverageAvailablePercent AND @CurrentOverage = @BestOverage AND @TicketCount = @BestTicketCount AND @SmallestTicketNumber >= @BestSmallestTicketNumber)
       )
    BEGIN
        RETURN;
    END

    -- Insert debugging information into the temporary table (optional)
    IF OBJECT_ID('tempdb..#DebugLog') IS NOT NULL
    BEGIN
        INSERT INTO #DebugLog (TargetSum, CurrentSum, SelectedIDs, LastID)
        VALUES (@TargetSum, @CurrentSum, @SelectedIDs, @LastID);
    END

    -- Declare variables for cursor
    DECLARE @NextID INT,
            @AvailableAmount INT,
            @TicketID VARCHAR(50),
            @TicketType VARCHAR(50),
            @AvailablePercent DECIMAL(18,2);

    -- Use the function to get tickets
    DECLARE TicketCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        ID,
        Available_Amount,
        Ticket,
        Intention,
        Available_Percent
    FROM dbo.GetAvailableTickets_ByPledgee(@Pledgee)
    WHERE ID > @LastID
      AND (@IncludeAllTypes = 1 OR Intention = @PriorityTicketType)
    ORDER BY
        CASE WHEN Intention = @PriorityTicketType THEN 0 ELSE 1 END,
        Ticket; -- Prioritize priority ticket type and smaller ticket numbers

    OPEN TicketCursor;

    FETCH NEXT FROM TicketCursor INTO @NextID, @AvailableAmount, @TicketID, @TicketType, @AvailablePercent;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Prepare new parameters for recursion
        DECLARE @NewSum INT = @CurrentSum + @AvailableAmount;
        DECLARE @NewSelectedIDs VARCHAR(MAX) = CASE
            WHEN LEN(@SelectedIDs) = 0 THEN @TicketID
            ELSE @SelectedIDs + ',' + @TicketID
        END;

        DECLARE @NewAvailablePercentSum DECIMAL(18,2) = @AvailablePercentSum + @AvailablePercent;
        DECLARE @NewTicketCount INT = @TicketCount + 1;

        DECLARE @NewSmallestTicketNumber VARCHAR(50) = @SmallestTicketNumber;
        IF @SmallestTicketNumber IS NULL OR @TicketID < @SmallestTicketNumber
        BEGIN
            SET @NewSmallestTicketNumber = @TicketID;
        END

        -- Recursive call
        EXEC GetBestTicketsRecursive
            @TargetSum = @TargetSum,
            @Pledgee = @Pledgee,
            @CurrentSum = @NewSum,
            @SelectedIDs = @NewSelectedIDs,
            @LastID = @NextID,
            @PriorityTicketType = @PriorityTicketType,
            @IncludeAllTypes = @IncludeAllTypes,
            @AvailablePercentSum = @NewAvailablePercentSum,
            @TicketCount = @NewTicketCount,
            @SmallestTicketNumber = @NewSmallestTicketNumber,
            @BestSum = @BestSum OUTPUT,
            @BestCombination = @BestCombination OUTPUT,
            @BestAverageAvailablePercent = @BestAverageAvailablePercent OUTPUT,
            @BestOverage = @BestOverage OUTPUT,
            @BestTicketCount = @BestTicketCount OUTPUT,
            @BestSmallestTicketNumber = @BestSmallestTicketNumber OUTPUT;

        FETCH NEXT FROM TicketCursor INTO @NextID, @AvailableAmount, @TicketID, @TicketType, @AvailablePercent;
    END

    CLOSE TicketCursor;
    DEALLOCATE TicketCursor;
END
GO
