SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[GetBestTicketsRecursive_Mode1]
    @TargetSum INT,
    @CurrentSum INT = 0,
    @SelectedIDs VARCHAR(MAX) = '',
    @LastID INT = 0,
    @Pledgee VARCHAR(50) = NULL,
    @PriorityTicketType VARCHAR(50) = 'AFS',
    @IncludeAllTypes BIT = 0,
    @PledgeeSum INT = 0,
    @SmallestTicketNumber VARCHAR(50) = NULL,
    @BestSum INT = NULL OUTPUT,
    @BestCombination VARCHAR(MAX) = NULL OUTPUT,
    @BestPledgeeSum INT = NULL OUTPUT,
    @BestSmallestTicketNumber VARCHAR(50) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Base Case
    IF @CurrentSum >= @TargetSum
    BEGIN
        IF (@BestSum IS NULL) OR
           (@PledgeeSum > @BestPledgeeSum) OR
           (@PledgeeSum = @BestPledgeeSum AND @CurrentSum < @BestSum) OR
           (@PledgeeSum = @BestPledgeeSum AND @CurrentSum = @BestSum AND @SmallestTicketNumber < @BestSmallestTicketNumber)
        BEGIN
            SET @BestSum = @CurrentSum;
            SET @BestCombination = @SelectedIDs;
            SET @BestPledgeeSum = @PledgeeSum;
            SET @BestSmallestTicketNumber = @SmallestTicketNumber;
        END
        RETURN;
    END

    -- Pruning Logic
    IF @BestSum IS NOT NULL AND
       (@PledgeeSum < @BestPledgeeSum OR
        (@PledgeeSum = @BestPledgeeSum AND @CurrentSum > @BestSum) OR
        (@PledgeeSum = @BestPledgeeSum AND @CurrentSum = @BestSum AND @SmallestTicketNumber >= @BestSmallestTicketNumber))
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
    DECLARE @NextID INT, @Amount INT, @TicketID VARCHAR(50), @PledgeeName VARCHAR(50), @Type VARCHAR(50);

    -- Declare cursor over a static SELECT statement with optional filters
    DECLARE TicketCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ID, Amount, Ticket, Pledgee, TicketType
    FROM Tickets
    WHERE ID > @LastID
      AND (@IncludeAllTypes = 1 OR TicketType = @PriorityTicketType)
    ORDER BY CASE WHEN Pledgee = @Pledgee THEN 0 ELSE 1 END, Ticket; -- Prioritize specified pledgee's tickets

    OPEN TicketCursor;

    FETCH NEXT FROM TicketCursor INTO @NextID, @Amount, @TicketID, @PledgeeName, @Type;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Prepare new parameters for recursion
        DECLARE @NewSum INT = @CurrentSum + @Amount;
        DECLARE @NewPledgeeSum INT = @PledgeeSum;
        IF @PledgeeName = @Pledgee
        BEGIN
            SET @NewPledgeeSum = @PledgeeSum + @Amount;
        END

        DECLARE @NewSelectedIDs VARCHAR(MAX) = CASE
            WHEN LEN(@SelectedIDs) = 0 THEN @TicketID
            ELSE @SelectedIDs + ',' + @TicketID
        END;

        DECLARE @NewSmallestTicketNumber VARCHAR(50) = @SmallestTicketNumber;
        IF @SmallestTicketNumber IS NULL OR @TicketID < @SmallestTicketNumber
        BEGIN
            SET @NewSmallestTicketNumber = @TicketID;
        END

        -- Recursive call
        EXEC GetBestTicketsRecursive_Mode1
            @TargetSum = @TargetSum,
            @CurrentSum = @NewSum,
            @SelectedIDs = @NewSelectedIDs,
            @LastID = @NextID,
            @Pledgee = @Pledgee,
            @PriorityTicketType = @PriorityTicketType,
            @IncludeAllTypes = @IncludeAllTypes,
            @PledgeeSum = @NewPledgeeSum,
            @SmallestTicketNumber = @NewSmallestTicketNumber,
            @BestSum = @BestSum OUTPUT,
            @BestCombination = @BestCombination OUTPUT,
            @BestPledgeeSum = @BestPledgeeSum OUTPUT,
            @BestSmallestTicketNumber = @BestSmallestTicketNumber OUTPUT;

        FETCH NEXT FROM TicketCursor INTO @NextID, @Amount, @TicketID, @PledgeeName, @Type;
    END

    CLOSE TicketCursor;
    DEALLOCATE TicketCursor;
END
GO
