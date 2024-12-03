
SELECT * FROM Ticket_Hold 

Update Tickets SET TicketType = (SELECT Ticket_Hold.Pledgee FROM Ticket_Hold Where Ticket_Hold.ID = Tickets.ID)

Update Tickets SET Pledgee  = (SELECT Ticket_Hold.TicketType FROM Ticket_Hold Where Ticket_Hold.ID = Tickets.ID)