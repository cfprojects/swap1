/****** Object:  Table [dbo].[Session_Save]    Script Date: 04/08/2009 19:29:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Session_Save](
	[ssid1] [char](35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ssid2] [char](35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[session_info] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[change_date] [datetime] NOT NULL,
 CONSTRAINT [PK_Session_Save] PRIMARY KEY CLUSTERED 
(
	[ssid1] ASC,
	[ssid2] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF