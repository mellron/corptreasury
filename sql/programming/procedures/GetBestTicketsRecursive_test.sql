CREATE OR ALTER PROCEDURE [dbo].[GetBestTicketsRecursive_test]
    @TargetSum INT,
    @CurrentSum INT = 0,
    @SelectedIDs VARCHAR(MAX) = '',
    @LastID INT = 0,
    @PriorityTicketType VARCHAR(50) = 'AFS',
    @IncludeAllTypes BIT = 0,
    @AvailablePercentSum DECIMAL(10,2) = 0, -- Sum of Available_Percent
    @TicketCount INT = 0, -- Number of tickets selected
    @SmallestTicketNumber VARCHAR(50) = NULL,
    @BestSum INT = NULL OUTPUT,
    @BestCombination VARCHAR(MAX) = NULL OUTPUT,
    @BestAverageAvailablePercent DECIMAL(10,2) = NULL OUTPUT,
    @BestOverage INT = NULL OUTPUT, -- New parameter
    @BestTicketCount INT = NULL OUTPUT,
    @BestSmallestTicketNumber VARCHAR(50) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Base Case
    IF @CurrentSum >= @TargetSum
    BEGIN
        DECLARE @Overage INT = @CurrentSum - @TargetSum;
        DECLARE @CurrentAverageAvailablePercent DECIMAL(10,2) = @AvailablePercentSum / @TicketCount;

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
    IF @BestAverageAvailablePercent IS NOT NULL AND
       (
           (@AvailablePercentSum / NULLIF(@TicketCount, 0)) < @BestAverageAvailablePercent OR
           ((@AvailablePercentSum / NULLIF(@TicketCount, 0)) = @BestAverageAvailablePercent AND (@CurrentSum - @TargetSum) > @BestOverage) OR
           ((@AvailablePercentSum / NULLIF(@TicketCount, 0)) = @BestAverageAvailablePercent AND (@CurrentSum - @TargetSum) = @BestOverage AND @TicketCount > @BestTicketCount) OR
           ((@AvailablePercentSum / NULLIF(@TicketCount, 0)) = @BestAverageAvailablePercent AND (@CurrentSum - @TargetSum) = @BestOverage AND @TicketCount = @BestTicketCount AND @SmallestTicketNumber >= @BestSmallestTicketNumber)
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
    DECLARE @NextID INT, @Amount INT, @TicketID VARCHAR(50), @TicketType VARCHAR(50), @AvailablePercent DECIMAL(10,2);

    -- Declare cursor over a static SELECT statement with optional filters
    DECLARE TicketCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ID, Available, Ticket, Intention, Available_Percent
    FROM Tickets_VW
    WHERE ID > @LastID
      AND (@IncludeAllTypes = 1 OR Intention = @PriorityTicketType)
    ORDER BY CASE WHEN Intention = @PriorityTicketType THEN 0 ELSE 1 END, Ticket; -- Prioritize 'AFS' tickets and smaller ticket numbers

    OPEN TicketCursor;

    FETCH NEXT FROM TicketCursor INTO @NextID, @Amount, @TicketID, @TicketType, @AvailablePercent;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Prepare new parameters for recursion
        DECLARE @NewSum INT = @CurrentSum + @Amount;
        DECLARE @NewSelectedIDs VARCHAR(MAX) = CASE
            WHEN LEN(@SelectedIDs) = 0 THEN @TicketID
            ELSE @SelectedIDs + ',' + @TicketID
        END;

        DECLARE @NewAvailablePercentSum DECIMAL(10,2) = @AvailablePercentSum + @AvailablePercent;
        DECLARE @NewTicketCount INT = @TicketCount + 1;

        DECLARE @NewSmallestTicketNumber VARCHAR(50) = @SmallestTicketNumber;
        IF @SmallestTicketNumber IS NULL OR @TicketID < @SmallestTicketNumber
        BEGIN
            SET @NewSmallestTicketNumber = @TicketID;
        END

        -- Recursive call
        EXEC GetBestTicketsRecursive_test
            @TargetSum = @TargetSum,
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

        FETCH NEXT FROM TicketCursor INTO @NextID, @Amount, @TicketID, @TicketType, @AvailablePercent;
    END

    CLOSE TicketCursor;
    DEALLOCATE TicketCursor;
END
GO
