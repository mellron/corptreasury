SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[sp_GetEligibleTickets]
    @PledgeAmount INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Temporary table to store eligible tickets
    CREATE TABLE #EligibleTickets (
        Ticket VARCHAR(50),
        UnpledgeAmt INT
    );

    -- Temporary table for testing combinations
    CREATE TABLE #TempSelection (
        Ticket VARCHAR(50),
        UnpledgeAmt INT
    );

    DECLARE @CurrentSum INT = 0;
    DECLARE @BestSum INT = NULL;

    -- Order by descending UnpledgeAmt to use larger tickets first
    DECLARE TicketCursor CURSOR FOR
    SELECT Ticket, UnpledgeAmt
    FROM UnpledgeAmt
    ORDER BY UnpledgeAmt DESC;

    DECLARE @Ticket VARCHAR(50);
    DECLARE @Amount INT;

    OPEN TicketCursor;

    FETCH NEXT FROM TicketCursor INTO @Ticket, @Amount;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Try adding this ticket
        IF @CurrentSum + @Amount >= @PledgeAmount
        BEGIN
            -- If sum meets or exceeds pledge, save current combination
            INSERT INTO #TempSelection (Ticket, UnpledgeAmt)
            VALUES (@Ticket, @Amount);

            SET @CurrentSum = @CurrentSum + @Amount;

            -- Check if it's a valid solution
            IF @BestSum IS NULL OR @CurrentSum < @BestSum
            BEGIN
                DELETE FROM #EligibleTickets;
                INSERT INTO #EligibleTickets SELECT * FROM #TempSelection;
                SET @BestSum = @CurrentSum;
            END
        END
        ELSE
        BEGIN
            -- Add to temporary if still below pledge
            INSERT INTO #TempSelection (Ticket, UnpledgeAmt)
            VALUES (@Ticket, @Amount);
            SET @CurrentSum = @CurrentSum + @Amount;
        END

        FETCH NEXT FROM TicketCursor INTO @Ticket, @Amount;
    END

    CLOSE TicketCursor;
    DEALLOCATE TicketCursor;

    -- Return the best matching tickets
    SELECT * FROM #EligibleTickets;

    DROP TABLE #EligibleTickets;
    DROP TABLE #TempSelection;
END;
GO
