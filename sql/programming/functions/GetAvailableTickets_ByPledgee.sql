CREATE FUNCTION dbo.GetAvailableTickets_ByPledgee (@Pledgee VARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ID,
        Ticket,
        Intention,
        Original_Amount AS Amount,
        Pledged,
        Pledgee AS TicketPledgee,
        -- Calculate Available_Amount based on @Pledgee
        CASE 
            WHEN @Pledgee = Pledgee THEN Original_Amount
            ELSE Original_Amount - Pledged
        END AS Available_Amount,
        -- Calculate Available_Percent based on @Pledgee
        CASE 
            WHEN @Pledgee = Pledgee THEN 100.00
            ELSE (Original_Amount - Pledged) * 100.0 / Original_Amount
        END AS Available_Percent
    FROM Tickets_VW
);
GO