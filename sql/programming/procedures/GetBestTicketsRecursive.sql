SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[GetBestTicketsRecursive]
    @TargetSum INT,
    @CurrentSum INT = 0,
    @SelectedIDs VARCHAR(MAX) = '',
    @LastID INT = 0,
    @BestSum INT = NULL OUTPUT,
    @BestCombination VARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Base Case
    IF @CurrentSum >= @TargetSum
    BEGIN
        IF @BestSum IS NULL OR @CurrentSum < @BestSum
        BEGIN
            SET @BestSum = @CurrentSum;
            SET @BestCombination = @SelectedIDs;
        END
        RETURN;
    END

    -- Pruning
    IF @BestSum IS NOT NULL AND @CurrentSum >= @BestSum
    BEGIN
        RETURN;
    END

    -- Insert debugging information into the temporary table
    INSERT INTO #DebugLog (TargetSum, CurrentSum, SelectedIDs, LastID)
    VALUES (@TargetSum, @CurrentSum, @SelectedIDs, @LastID);

    -- Recursive Case
    DECLARE @NextID INT, @Value INT, @Ticket VARCHAR(50);
    DECLARE TicketCursor CURSOR LOCAL FOR
        SELECT ID, Amount, Ticket
        FROM Tickets
        WHERE ID > @LastID
        ORDER BY ID;

    OPEN TicketCursor;

    FETCH NEXT FROM TicketCursor INTO @NextID, @Value, @Ticket;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Prepare new parameters
        DECLARE @NewSum INT = @CurrentSum + @Value;
        DECLARE @NewSelectedIDs VARCHAR(MAX) = CASE
            WHEN LEN(@SelectedIDs) = 0 THEN @Ticket
            ELSE @SelectedIDs + ',' + @Ticket
        END;

        -- Recursive call
        EXEC GetBestTicketsRecursive
            @TargetSum,
            @NewSum,
            @NewSelectedIDs,
            @NextID,
            @BestSum OUTPUT,
            @BestCombination OUTPUT;

        FETCH NEXT FROM TicketCursor INTO @NextID, @Value, @Ticket;
    END

    CLOSE TicketCursor;
    DEALLOCATE TicketCursor;
END
GO
