SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[Tickets]
GO

CREATE TABLE [dbo].[Tickets](
    [ID] [int] IDENTITY(1,1) NOT NULL,
    [Ticket] [varchar](50) NOT NULL,
    [Pledged] [int] DEFAULT 0 NOT NULL, -- This is the amount that has been pledged
    [Amount] [int] NULL, -- This is the Original Pledged amout
    [Pledgee] [varchar](50) NULL, -- This is who it is pledged too
    [TicketType] [varchar](50) NULL -- AFS OR HTM
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Tickets] ADD PRIMARY KEY CLUSTERED 
(
    [ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
ALTER TABLE [dbo].[Tickets] ADD  CONSTRAINT [Tickets_UniqueTicket] UNIQUE NONCLUSTERED 
(
    [Ticket] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO



INSERT INTO [dbo].[Tickets] (Ticket,Pledged, Amount, Pledgee, TicketType)
VALUES
    ('287000130',0, 50, 'RSWP1', 'AFS'),
    ('287000245',0, 50, 'RSWP1', 'AFS'),
    ('287000254',25, 50, 'ARIMU', 'AFS'),
    ('287000255',0, 20, 'ARIMU', 'AFS'),
    ('287000258',0, 20, 'ARIMU', 'AFS'),
    ('287000259',5, 20, 'ILVWH', 'AFS'),
    ('287000260',5, 10, 'ILVWH', 'HTM'),
    ('287000261',0, 30, 'RSWP1', 'HTM'),
    ('287000262',0, 60, 'RSWP1', 'HTM')


-- Update unspecified columns (Pledged default to 0)
UPDATE [dbo].[Tickets]
SET Pledged = 0
WHERE Pledged IS NULL;
