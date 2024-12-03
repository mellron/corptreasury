DELETE FROM Tickets
GO

INSERT INTO Tickets (ID, Ticket, Amount, Pledgee, TicketType) VALUES
(1, 'T1', 50, 'John', 'ACH'),
(2, 'T11', 50, 'Don', 'ACH'),
(3, 'T13', 30, 'John', 'ACH'),
(4, 'T14', 20, 'Don', 'HTM'),
(5, 'T4', 20, 'John', 'ACH'),
(6, 'T7', 15, 'John', 'ACH'),
(7, 'T10', 15, 'Don', 'ACH'),
(8, 'T8', 10, 'Don', 'ACH'),
(9, 'T5', 10, 'John', 'ACH'),
(10, 'T2', 10, 'John', 'ACH'),
(11, 'T3', 5, 'John', 'ACH'),
(12, 'T6', 5, 'John', 'ACH'),
(13, 'T9', 5, 'John', 'ACH'),
(14, 'T12', 5, 'Don', 'ACH'),
(15, 'T15', 1, 'John', 'HTM'),
(16, 'T16', 1, 'Don', 'HTM')

GO
