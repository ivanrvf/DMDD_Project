create database vrs;
use vrs;
CREATE TABLE [dbo].[Users](
	[UserID] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](100) NULL,
	[LastName] [nvarchar](100) NULL,
	[Birthdate] [datetime2](7) NULL,
	[Gender] [nvarchar](10) NULL,
	[PhoneNumber] [nvarchar](10) UNIQUE NULL,
	[SSN] [nvarchar](9) UNIQUE NULL,
	[Type] [nvarchar](10) NULL
	 CHECK (([Type]='Customer' OR [Type]='Business' OR [Type]='Admin'))
)

CREATE TABLE [dbo].[UserAuthentication](
	[username] [nvarchar](250) UNIQUE,
	[LastLogin] [datetime2](7) NULL,
	[Token] [nvarchar](250) NULL,
	[UserID] [int] FOREIGN KEY REFERENCES Users(UserID),
	[password] [varbinary](400) UNIQUE
)
CREATE TABLE [dbo].[Business](
	[BusinessID] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[BusinessName] [nvarchar](30) NULL,
	[Individual] [char](5) NULL,
	[BusinessLicenseNo] [nvarchar](100) NULL
)
CREATE TABLE [dbo].[Customer](
	[LicenceNumber] [int] NOT NULL,
	[ExpiryDate] [datetime2](7) NOT NULL,
	[EIN] [nvarchar](50) NULL,
	[Designation] [nvarchar](50) NULL,
	[WorkEmail] [nvarchar](50) NULL,
	[Fax] [nvarchar](50) NULL,
	[UserID] [int] FOREIGN KEY REFERENCES Users(UserID),
	[BusinessID] [int] FOREIGN KEY REFERENCES Business(BusinessID)
)

CREATE TABLE [dbo].[Admin](
	[Role] [nvarchar](50) NULL,
	[WorkEmail] [nvarchar](50) NULL,
	[EIN] [nvarchar](50) NULL,
	[UserID] [int] FOREIGN KEY REFERENCES Users(UserID)
	)

CREATE TABLE [dbo].[Promotions](
	[PromotionID] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[PromotionName] [nvarchar](250) NULL,
	[From] [datetime2](7) NULL,
	[To] [datetime2](7) NULL,
	[Discount] [int] NULL,
	[UserID] [int] FOREIGN KEY REFERENCES Users(UserID)
);

CREATE TABLE [dbo].[VehicleCategory](
	[VehicleCategoryID] [int] PRIMARY KEY IDENTITY(1,1),
	[VehicleCategoryName] [nvarchar](250) NULL,
	[UserID] [int] FOREIGN KEY REFERENCES Users(UserID)
);

CREATE TABLE [dbo].[PaymentType](
	[PaymentTypeID] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[PaymentName] [nvarchar](250) NOT NULL,
	[CreatedOn] [datetime2](7) NULL,
	[UserID] [int] FOREIGN KEY REFERENCES Users(UserID)
);

CREATE TABLE [dbo].[PaymentMethods](
	[PaymentMethodID] [int] PRIMARY KEY IDENTITY(1,1),
	[CardNumber] [int] NOT NULL,
	[ExpiryDate] [datetime2](7) NOT NULL,
	[AccountNumber] [int] NOT NULL,
	[RoutingNumber] [int] NOT NULL,
	[UserID] int FOREIGN KEY REFERENCES Users(UserID),
	[PaymentTypeID] int FOREIGN KEY REFERENCES PaymentType(PaymentTypeID)
);

CREATE TABLE [dbo].[Location](
	[LocationID] [int] PRIMARY KEY IDENTITY(1,1),
	[Region] [char](100) NULL,
	[UserID] int FOREIGN KEY REFERENCES Users(UserID),
	[State] [char](5) NULL
);

CREATE TABLE [dbo].[Insurance](
	[InsuranceID] [int] PRIMARY KEY IDENTITY(1,1),
	[InsuranceName] [nvarchar](100) NULL,
	[UserID] [int] FOREIGN KEY REFERENCES Users(UserID)
);

create function [dbo].[addVehicleSeatProperty](@vehicleCategoryId int)
returns int
as 
Begin
return case when @vehicleCategoryId = 1 then 4
		when @vehicleCategoryId = 2 then 7
		when @vehicleCategoryId = 3 then 2
		end
End

CREATE TABLE [dbo].[Vehicles](
	[VehicleID] [int] PRIMARY KEY IDENTITY(1,1),
	[Make] [nvarchar](50) NULL,
	[License] [nvarchar](100) NOT NULL,
	[Model] [nvarchar](200) NULL,
	[VehicleCategoryID] [int] NULL,
	[BusinessID] [int] FOREIGN KEY REFERENCES BUSINESS(BusinessID),
	[seats]  AS ([dbo].[addVehicleSeatProperty]([VehicleCategoryID]))
)

CREATE TABLE [dbo].[VehiclePool](
	[VehiclePoolID] [int] PRIMARY KEY IDENTITY(1,1),
	[Availability] [bit] NULL,
	[LocationID] [int] FOREIGN KEY REFERENCES Location(LocationID),
	[Amount] [int] NULL,
	[VehicleID] [int] FOREIGN KEY REFERENCES [Vehicles](VehicleID),
	[From] [datetime] NOT NULL,
	[To] [datetime] NOT NULL
)

CREATE TABLE [dbo].[Bookings](
	[BookingID] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[CreatedDate] [datetime2](7) DEFAULT(getdate()),
	[UserID] [int] FOREIGN KEY REFERENCES Users(UserID),
	[VehiclePoolID] [int] FOREIGN KEY REFERENCES VehiclePool(VehiclePoolID),
	[InsuranceID] [int] FOREIGN KEY REFERENCES Insurance(InsuranceID),
	[CancelBookingID] [int] NULL,
	[PromotionID] [int] FOREIGN KEY REFERENCES Promotions(PromotionID),
	[From] [datetime2](7) NULL,
	[To] [datetime2](7) NULL
)
CREATE TABLE [dbo].[Transactions](
	[TransactionID] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[CreatedDate] [datetime2](7) NULL,
	[BookingID] [int] FOREIGN KEY REFERENCES Bookings(BookingID),
	[Amount] [int] NULL
)
CREATE TABLE [dbo].[Payment_Info](
	[PaymentID] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[Payment_Method] [nvarchar](100) NULL,
	[Amount] [money] NULL,
	[CreatedOn] [datetime2](7) NULL,
	[PaymentMethodID] [int] FOREIGN KEY REFERENCES PaymentMethods(PaymentMethodID),
	[TransactionID] [int] FOREIGN KEY REFERENCES transactions(TransactionID),
	)

	CREATE NONCLUSTERED INDEX [search_index] ON [dbo].[Bookings]
(
	[UserID] ASC,
	[VehiclePoolID] ASC,
	[PromotionID] ASC,
	[CancelBookingID] ASC,
	[CreatedDate] ASC
)