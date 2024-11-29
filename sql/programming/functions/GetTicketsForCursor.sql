SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[GetTicketsForCursor](
    @LastID INT,
    @Pledgee VARCHAR(50),
    @PriorityTicketType VARCHAR(50),
    @IncludeAllTypes BIT
)
RETURNS TABLE
AS
RETURN
(
    SELECT ID, Amount, Ticket, Pledgee, TicketType
    FROM Tickets
    WHERE ID > @LastID
      AND (@Pledgee IS NULL OR Pledgee = @Pledgee)
      AND (@IncludeAllTypes = 1 OR TicketType = @PriorityTicketType)
)
GO
