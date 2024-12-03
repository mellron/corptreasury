SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ******************************************************************************************************************
-- ** Title: GetBestTicketsRecursive
-- ** Description: A recursive stored procedure to find the best combination of tickets for a given target sum
-- **
-- ** Parameters: @TargetSum INT - The target sum to achieve
-- **             @CurrentSum INT - The current sum in the recursion
-- **             @SelectedIDs VARCHAR(MAX) - The selected ticket IDs in the recursion
-- **             @LastID INT - The last ticket ID processed
-- **             @Pledgee VARCHAR(50) - The pledgee to filter tickets by
-- **             @PriorityTicketType VARCHAR(50) - The priority ticket type to include
-- **             @IncludeAllTypes BIT - Flag to include all ticket types
-- **             @BestSum INT OUTPUT - The best sum achieved
-- **             @BestCombination VARCHAR(MAX) OUTPUT - The best combination of ticket IDs
-- **
-- ** Returns: None
-- **
-- ** Author : Douglas Tolley
-- ** Date   : 2024-11-28
-- **
-- ** Change History
-- ** --------------
-- ** updated by        update date
-- ** ----------        ----------
-- ** detolle           2024-11-28
-- ******************************************************************************************************************

CREATE OR ALTER PROCEDURE [dbo].[GetBestTicketsRecursive]
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
    @BestSmallestTicketNumber VARCHAR(50) = NULL OUTPUT,
    @PrioritizePledgeeSum INT = 0 -- 0: minimize total amount, 1: prioritize pledgee sum, 2: use only pledgee's tickets
AS
BEGIN
    SET NOCOUNT ON

    -- Base Case
    IF @CurrentSum >= @TargetSum
    BEGIN
        DECLARE @UpdateBest BIT = 0

        IF (@BestSum IS NULL)
        BEGIN
            SET @UpdateBest = 1
        END
        ELSE
        BEGIN
             -- Determine the prioritization strategy based on @PrioritizePledgeeSum
            IF @PrioritizePledgeeSum = 0
            BEGIN
                -- Mode 0: Minimize total amount (default behavior)
                -- Update the best combination if:
                IF @CurrentSum < @BestSum OR  -- 1. Found a combination with a smaller total amount
                   (@CurrentSum = @BestSum AND @PledgeeSum > @BestPledgeeSum) OR  -- 2. Same total amount but higher sum of specified pledgee's tickets
                   (@CurrentSum = @BestSum AND @PledgeeSum = @BestPledgeeSum AND @SmallestTicketNumber < @BestSmallestTicketNumber)
                   -- 3. Same total amount and pledgee sum, but smaller ticket number
                BEGIN
                    SET @UpdateBest = 1  -- Mark to update the best combination found so far
                END
            END
            ELSE IF @PrioritizePledgeeSum = 1
            BEGIN
                -- Mode 1: Prioritize combinations with higher sum of specified pledgee's tickets
                -- Update the best combination if:
                IF @PledgeeSum > @BestPledgeeSum OR  -- 1. Found a combination with a higher sum of the specified pledgee's tickets
                   (@PledgeeSum = @BestPledgeeSum AND @CurrentSum < @BestSum) OR  -- 2. Same pledgee sum but smaller total amount
                   (@PledgeeSum = @BestPledgeeSum AND @CurrentSum = @BestSum AND @SmallestTicketNumber < @BestSmallestTicketNumber)
                   -- 3. Same pledgee sum and total amount, but smaller ticket number
                BEGIN
                    SET @UpdateBest = 1 -- Mark to update the best combination found so far
                END
            END
            ELSE IF @PrioritizePledgeeSum = 2
            BEGIN
                -- Mode 2: Use only tickets from the specified pledgee
                -- Update the best combination if all tickets are from the specified pledgee and:
                IF (@PledgeeSum = @CurrentSum) AND  -- All tickets in the combination belong to the specified pledgee
                   (@CurrentSum < @BestSum OR  -- 1. Found a combination with a smaller total amount
                   (@CurrentSum = @BestSum AND @SmallestTicketNumber < @BestSmallestTicketNumber))  -- 2. Same total amount but smaller ticket number
                BEGIN
                    SET @UpdateBest = 1  -- Mark to update the best combination found so far
                END
            END
        END

        RETURN
    END

    -- Pruning Logic
    IF @BestSum IS NOT NULL AND
        (
            (@PrioritizePledgeeSum = 0 AND
                (@CurrentSum > @BestSum OR
                (@CurrentSum = @BestSum AND @PledgeeSum < @BestPledgeeSum) OR
                (@CurrentSum = @BestSum AND @PledgeeSum = @BestPledgeeSum AND @SmallestTicketNumber >= @BestSmallestTicketNumber))
            )
            OR
            (@PrioritizePledgeeSum = 1 AND
                (@PledgeeSum < @BestPledgeeSum OR
                (@PledgeeSum = @BestPledgeeSum AND @CurrentSum > @BestSum) OR
                (@PledgeeSum = @BestPledgeeSum AND @CurrentSum = @BestSum AND @SmallestTicketNumber >= @BestSmallestTicketNumber))
            )
            OR
            (@PrioritizePledgeeSum = 2 AND
                (@PledgeeSum < @CurrentSum OR
                (@PledgeeSum = @CurrentSum AND @CurrentSum > @BestSum) OR
                (@PledgeeSum = @CurrentSum AND @CurrentSum = @BestSum AND @SmallestTicketNumber >= @BestSmallestTicketNumber))
            )
        )
    BEGIN
        RETURN
    END

    -- Insert debugging information into the temporary table (optional)
    IF OBJECT_ID('tempdb..#DebugLog') IS NOT NULL
    BEGIN
        INSERT INTO #DebugLog (TargetSum, CurrentSum, SelectedIDs, LastID)
        VALUES (@TargetSum, @CurrentSum, @SelectedIDs, @LastID)
    END

    -- Declare variables for cursor
    DECLARE @NextID INT, @Amount INT, @TicketID VARCHAR(50), @PledgeeName VARCHAR(50), @Type VARCHAR(50)

    -- Declare cursor over a static SELECT statement with optional filters
    DECLARE TicketCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ID, Amount, Ticket, Pledgee, TicketType
    FROM Tickets
    WHERE ID > @LastID
      AND (@IncludeAllTypes = 1 OR TicketType = @PriorityTicketType)
      AND (@PrioritizePledgeeSum <> 2 OR Pledgee = @Pledgee)
    ORDER BY CASE WHEN Pledgee = @Pledgee THEN 0 ELSE 1 END, Ticket -- Order by Ticket number to prioritize smaller tickets

    OPEN TicketCursor

    FETCH NEXT FROM TicketCursor INTO @NextID, @Amount, @TicketID, @PledgeeName, @Type

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Prepare new parameters for recursion
        DECLARE @NewSum INT = @CurrentSum + @Amount
        DECLARE @NewPledgeeSum INT = @PledgeeSum
        IF @PledgeeName = @Pledgee
        BEGIN
            SET @NewPledgeeSum = @PledgeeSum + @Amount
        END

        DECLARE @NewSelectedIDs VARCHAR(MAX) = CASE
            WHEN LEN(@SelectedIDs) = 0 THEN @TicketID
            ELSE @SelectedIDs + ',' + @TicketID
        END

        DECLARE @NewSmallestTicketNumber VARCHAR(50) = @SmallestTicketNumber
        IF @SmallestTicketNumber IS NULL OR @TicketID < @SmallestTicketNumber
        BEGIN
            SET @NewSmallestTicketNumber = @TicketID
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
            @PledgeeSum = @NewPledgeeSum,
            @SmallestTicketNumber = @NewSmallestTicketNumber,
            @BestSum = @BestSum OUTPUT,
            @BestCombination = @BestCombination OUTPUT,
            @BestPledgeeSum = @BestPledgeeSum OUTPUT,
            @BestSmallestTicketNumber = @BestSmallestTicketNumber OUTPUT,
            @PrioritizePledgeeSum = @PrioritizePledgeeSum

        FETCH NEXT FROM TicketCursor INTO @NextID, @Amount, @TicketID, @PledgeeName, @Type
    END

    CLOSE TicketCursor
    DEALLOCATE TicketCursor

END
GO
