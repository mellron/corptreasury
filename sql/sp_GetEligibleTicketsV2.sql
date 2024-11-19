SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_GetEligibleTicketsV2]
    @PledgeAmount INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Recursive CTE to find all combinations of tickets
    WITH RecursiveCombinations AS (
        SELECT
            Ticket,
            UnpledgeAmt,
            CAST(Ticket AS VARCHAR(MAX)) AS ComboTickets,
            UnpledgeAmt AS ComboSum
        FROM UnpledgeAmt
        WHERE UnpledgeAmt <= @PledgeAmount

        UNION ALL

        SELECT
            u.Ticket,
            u.UnpledgeAmt,
            CAST(rc.ComboTickets + ',' + u.Ticket AS VARCHAR(MAX)) AS ComboTickets,
            rc.ComboSum + u.UnpledgeAmt AS ComboSum
        FROM UnpledgeAmt u
        INNER JOIN RecursiveCombinations rc
            ON rc.ComboTickets NOT LIKE '%' + u.Ticket + '%'
        WHERE rc.ComboSum + u.UnpledgeAmt <= @PledgeAmount + 50 -- Limit excess here
    )
    SELECT TOP 1 *
    FROM RecursiveCombinations
    WHERE ComboSum >= @PledgeAmount
    ORDER BY ComboSum ASC; -- Choose closest valid sum greater or equal
END;
GO
