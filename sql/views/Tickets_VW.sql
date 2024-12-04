CREATE OR ALTER VIEW [dbo].[Tickets_VW] AS
SELECT 
    ID,
    Ticket,
    TicketType AS Intention,
    Amount AS Original_Amount,
    Pledgee,
    Pledged,
    (Amount - Pledged) AS Available, -- Calculated column: Available = Amount - Pledged
    CASE 
        WHEN Amount > 0 THEN CAST((Amount - Pledged) * 100.0 / Amount AS DECIMAL(10, 2)) 
        ELSE 0 
    END AS Available_Percent -- Calculated column: Percentage of amount left
FROM 
    [dbo].[Tickets];
GO
