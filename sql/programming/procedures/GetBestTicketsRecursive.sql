SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[GetBestTicketsRecursive]
    @TargetSum INT,
    @CurrentSum INT = 0,
    @SelectedIDs VARCHAR(MAX) = '',
    @LastID INT = 0,
    @Pledgee VARCHAR(50) = NULL,
    @PriorityTicketType VARCHAR(50) = 'ACH',
    @IncludeAllTypes BIT = 0, -- New parameter to control ticket type inclusion@Ticket
    @BestSum INT = NULL OUTPUT,
    @BestCombination VARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Base Case: Check if the current sum meets or exceeds the target
    IF @CurrentSum >= @TargetSum
    BEGIN
        IF @BestSum IS NULL OR @CurrentSum < @BestSum
        BEGIN
            SET @BestSum = @CurrentSum
            SET @BestCombination = @SelectedIDs
        END
        RETURN
    END

    -- Pruning: Stop recursion if current sum cannot lead to a better solution
    IF @BestSum IS NOT NULL AND @CurrentSum >= @BestSum
    BEGIN
        RETURN
    END

    -- Insert debugging information into the temporary table
    INSERT INTO #DebugLog (TargetSum, CurrentSum, SelectedIDs, LastID)
    VALUES (@TargetSum, @CurrentSum, @SelectedIDs, @LastID)

    -- Declare variables for cursor
    DECLARE @NextID INT, @Amount INT, @TicketID VARCHAR(50), @PledgeeName VARCHAR(50), @Type VARCHAR(50)

    -- Declare cursor
    DECLARE TicketCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ID, Amount, Ticket, Pledgee, TicketType
    FROM Tickets
    WHERE ID > @LastID
      AND (@Pledgee IS NULL OR Pledgee = @Pledgee)
      AND (@IncludeAllTypes = 1 OR TicketType = @PriorityTicketType)
    ORDER BY ID

    OPEN TicketCursor

    FETCH NEXT FROM TicketCursor INTO @NextID, @Amount, @TicketID, @PledgeeName, @Type

    -- Start While loop for recursion

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Prepare new parameters for recursion
        DECLARE @NewSum INT = @CurrentSum + @Amount

        DECLARE @NewSelectedIDs VARCHAR(MAX) = CASE
            WHEN LEN(@SelectedIDs) = 0 THEN @TicketID
            ELSE @SelectedIDs + ',' + @TicketID
        END

        -- Recursive call
        EXEC GetBestTicketsRecursive
            @TargetSum = @TargetSum,
            @CurrentSum = @NewSum,
            @SelectedIDs = @NewSelectedIDs,
            @LastID = @NextID,
            @Pledgee = @Pledgee,
            @PriorityTicketType = @PriorityTicketType,
            @IncludeAllTypes = @IncludeAllTypes,
            @BestSum = @BestSum OUTPUT,
            @BestCombination = @BestCombination OUTPUT

        FETCH NEXT FROM TicketCursor INTO @NextID, @Amount, @TicketID, @PledgeeName, @Type
    END

    -- clean up cursor

    CLOSE TicketCursor

    DEALLOCATE TicketCursor
END
GO
