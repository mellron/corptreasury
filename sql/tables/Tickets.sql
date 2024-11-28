SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[Tickets]
GO

CREATE TABLE [dbo].[Tickets](
    [ID] [int] IDENTITY(1,1) NOT NULL,
    [Ticket] [varchar](50) NOT NULL,
    [Amount] [int] NULL,
    [Pledgee] [varchar](50) NULL,
    [TicketType] [varchar](50) NULL
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