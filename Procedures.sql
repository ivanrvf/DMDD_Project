USE [vehicle_renting_system]
GO
/****** Object:  StoredProcedure [dbo].[authenticateUser]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[authenticateUser]
@username nvarchar(250),
@password nvarchar(250),
@token nvarchar(250),
@inActive int = -5,
@userID int output,
@error nvarchar(500) output
as
Begin
	open symmetric key userAuth_sm decryption by certificate userPass;
	if @token is null and @username is not null and @password is not null
	begin 
		set @userID = (select UserID from UserAuthentication where 
		LastLogin > dateadd(minute,@inActive,getdate()) and 
		Username = @username and
		dbo.decryptPass(password) = @password);
	end
	else
	begin
		set @userID = (select UserID from UserAuthentication where 
		LastLogin > dateadd(minute,@inActive,getdate()) and 
		Token like @token);
	end
	if isnull(@userID,'') = ''
		begin
			set @error = ' User is invalid';
			set @userID = 0;
		end
end
GO


/****** Object:  StoredProcedure [dbo].[cancelBooking]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[cancelBooking] @BookingID INTEGER
AS
    set xact_abort on
    BEGIN TRANSACTION cancelBookingTransaction
    declare @discount int
    declare @totalhours int
    declare @amount int
    declare @transactionID int
    declare @UserID int
    declare @VehiclePoolID int
    declare @InsuranceID int
    declare @PromotionID int
    declare @cancel_bookingID int
    declare @PaymentMethodID int
    declare @From DATETIME2
    declare @To DATETIME2
    declare @paymentType NVARCHAR(250)
    SELECT @totalhours= DATEDIFF(HOUR,@To,@From)
    if @BookingID is not NULL
    BEGIN
        SELECT @UserID = UserID,@VehiclePoolID=VehiclePoolID,@InsuranceID=InsuranceID,@PromotionID=PromotionID,@From=[From],@To=[To] From Bookings WHERE Bookings.BookingID = @BookingID
        SELECT @cancel_bookingID = SCOPE_IDENTITY()
        SELECT @amount = Transactions.Amount, @transactionID = Transactions.TransactionID FROM Transactions WHERE Transactions.BookingID=@bookingID
        SELECT @PaymentMethodID = PaymentMethodID FROM Payment_Info WHERE TransactionID=@transactionID
    END
    if @PaymentMethodID is not NULL
    BEGIN
        SELECT @paymentType = PaymentType.PaymentName FROM PaymentMethods JOIN PaymentType ON PaymentMethods.PaymentTypeID=PaymentType.PaymentTypeID WHERE PaymentMethods.PaymentMethodID=@PaymentMethodID
    END
    INSERT INTO dbo.Bookings ( UserID, VehiclePoolID, InsuranceID, CancelBookingID, PromotionID) VALUES( @UserID, @VehiclePoolID, @InsuranceID, @BookingID, @PromotionID)
    SELECT @bookingID = SCOPE_IDENTITY()
    INSERT INTO dbo.Transactions ( BookingID, Amount) VALUES( @bookingID, -1*@amount)
    SELECT @transactionID = SCOPE_IDENTITY()
    INSERT INTO dbo.Payment_Info (Payment_Method, Amount, PaymentMethodID, TransactionID) VALUES(@paymentType,@amount, @PaymentMethodID,@transactionID)
    COMMIT TRANSACTION cancelBookingTransaction

GO


/****** Object:  StoredProcedure [dbo].[createBooking]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[createBooking]   @UserID INTEGER, @VehiclePoolID INTEGER, @InsuranceID INTEGER, @CancelBookingID INTEGER, @PromotionID INTEGER, @From DATETIME2, @To DATETIME2, @PaymentMethodID INTEGER
AS
    set xact_abort on
    BEGIN TRANSACTION createBookingTransaction
    declare @discount int 
    set @discount= 0
    declare @totalhours int
    declare @amount int
    declare @bookingID int
    declare @transactionID int
    declare @paymentType NVARCHAR(250)
    SELECT @totalhours= DATEDIFF(HOUR,@From,@To)
    if @PromotionID is not NULL
    BEGIN
        SELECT @discount = Discount FROM Promotions WHERE Promotions.PromotionID=@PromotionID
    END
    if @VehiclePoolID is not NULL
    BEGIN
        SELECT @amount = VehiclePool.Amount FROM VehiclePool WHERE VehiclePool.VehiclePoolID=@VehiclePoolID
    END
    PRINT @amount 
    PRINT @totalhours
    PRINT @discount
    if @PaymentMethodID is not NULL
    BEGIN
        SELECT @paymentType = PaymentType.PaymentName FROM PaymentMethods JOIN PaymentType ON PaymentMethods.PaymentTypeID=PaymentType.PaymentTypeID WHERE PaymentMethods.PaymentMethodID=@PaymentMethodID
    END
    INSERT INTO dbo.Bookings ( UserID, VehiclePoolID, InsuranceID, CancelBookingID, PromotionID,[From],[To]) VALUES( @UserID, @VehiclePoolID, @InsuranceID, @CancelBookingID, @PromotionID,@From,@To)
    SELECT @bookingID = SCOPE_IDENTITY()
    INSERT INTO dbo.Transactions ( BookingID, Amount) VALUES( @bookingID, @amount*@totalhours-@discount)
    SELECT @transactionID = SCOPE_IDENTITY()
    INSERT INTO dbo.Payment_Info (Payment_Method, Amount, PaymentMethodID, TransactionID) VALUES(@paymentType,@amount*@totalhours-@discount, @PaymentMethodID,@transactionID)
    COMMIT TRANSACTION createBookingTransaction
GO


/****** Object:  StoredProcedure [dbo].[createBusiness]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[createBusiness] 
	@BusinessName nvarchar(30), 
	@Individual char(5), 
	@BusinessLicenseNo nvarchar(100), 
	@id int output
as
Begin
	Insert into Business values( @BusinessName, @Individual, @BusinessLicenseNo);
	set @id = Scope_identity();
End
GO


/****** Object:  StoredProcedure [dbo].[createLocation]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[createLocation]( @region varchar(200),@userId int)
AS 
BEGIN
	DECLARE @locationId int;
	SET  @locationId=0;
	if EXISTS(select 1 from Location)
	BEGIN
		select @locationId=MAX(LocationID) from Location
		END
	set @locationId=@locationId+1;
insert into Location(LocationID,Region,UserID) values(@locationId,@region,@userId)
select @locationId
END
GO



/****** Object:  StoredProcedure [dbo].[createPaymentMethodByUserID]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[createPaymentMethodByUserID] 
@UserID int,
@CardNumber int,
@PaymentType nvarchar(10),
@AccountNumber int,
@RoutingNumber int,
@ExpiryDate datetime2, 
@PaymentMethodID int output
as
begin
/*
	declare @paymentId int;
	exec createPaymentMethodByUserID 1,1234567890,'Card',09876543209123,78123459089,'2017-09-12',@paymentId output
	select @paymentId;
*/
	Declare @TypeId int = (select PaymentTypeId from PaymentType where PaymentName like @PaymentType);
	if @PaymentType = 'Card'
	Begin
		open symmetric key userAuth_sm decryption by certificate userPass;
		insert into PaymentMethods(CardNumber,ExpiryDate,PaymentTypeID,UserID) 
		values(dbo.encryptPass(@CardNumber),@ExpiryDate,@TypeId,@UserID);
	End
	 else if @PaymentType = 'Account'
	Begin
		open symmetric key userAuth_sm decryption by certificate userPass;
		insert into PaymentMethods(AccountNumber,RoutingNumber,PaymentTypeID,UserID) 
		values(dbo.encryptPass(@AccountNumber),@RoutingNumber,@TypeId,@UserID);
	End
end
GO



/****** Object:  StoredProcedure [dbo].[createPaymentType]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[createPaymentType] @PaymentName NVARCHAR(250), @CreateOn DATETIME2, @UserID INTEGER
As
    INSERT INTO dbo.PaymentType (PaymentName, CreatedOn, UserID) VALUES (@PaymentName, @CreateOn, @UserID )

GO



/****** Object:  StoredProcedure [dbo].[createPromotion]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[createPromotion]( @promotionName varchar(500),@fromDatetime DateTime,@toDatetime DateTime ,@discount int,@userId int)
AS 
BEGIN
    insert into Promotions(PromotionName,[From],[To],Discount,UserID) values(@promotionName,@fromDatetime,@toDatetime,@discount,@userId)
END

GO




/****** Object:  StoredProcedure [dbo].[createUser]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[createUser] 
@FirstName nvarchar(100),
@LastName nvarchar(100),
@birthdate datetime2 ,
@Gender nvarchar(10),
@PhoneNumber nvarchar(10),
@SSN nvarchar(9),
@Type nvarchar(10),
@username nvarchar(250), 
@password nvarchar(250),
@role nvarchar(50),
@workEmail nvarchar(50),
@ein nvarchar(50),
@LicenceNo int, 
@expiryDate datetime2, 
@designation nvarchar(50), 
@fax nvarchar(50), 
@businessID int,
@userID int output,
@token nvarchar(250) output,
@errorMessage nvarchar(100) output
 AS
Begin
/*
Insert into Users values('Jay', 'a','98/02/2019' ,'Male','8901231234','123456789','Customer','jay','jay','employee','ivanrvf@gmail.com','123',0912345678, '10/09/2019', 'intern', '908098909', 12345)
*/
	If @FirstName like '[0-9]+' or isnull(@FirstName,'') = '' or @LastName like '[0-9]+' or isnull(@LastName,'') = ''
	Begin
		set @errorMessage = 'Invalid FirstName';
	end
	else if isnull(@birthdate,'') = ''
	Begin
		set @errorMessage = 'Invalid Birthdate';
	end
	else if isnull(@username,'') = '' or isnull(@password,'') = ''
	Begin
		set @errorMessage = 'Invalid Username/Password';
	end
	else if isnull(@SSN,'') = ''
	Begin
		set @errorMessage = ' Invalid SSN ';
	end
	else if isnull(@Type,'') = ''
	Begin
		set @errorMessage = 'Type is required'
	end
	else
	Begin
		Insert into Users values(@FirstName,@LastName,@birthdate,@Gender,@PhoneNumber,@SSN,@Type)
		set @userID = SCOPE_IDENTITY();
		if @Type = 'Admin'
		Begin
			insert into [Admin] values(@userID, @role, @workemail,@ein)
		end
		else if @Type = 'Customer'
		begin
			insert into [Customer] values ( @LicenceNo, @expiryDate, @ein, @designation, @workEmail, @fax,@userID, @businessID);
		end
		exec registerUser @username,@password,@userID, @token output, @errorMessage;
	end
End
GO



/****** Object:  StoredProcedure [dbo].[createVehicle]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[createVehicle]( @vehicleCategoryName varchar(200),@userId int)
AS 
BEGIN
	DECLARE @vehicleCatId int;
	SET  @vehicleCatId=0;
	if EXISTS(select * from VehicleCategory)
	BEGIN
		select @vehicleCatId=MAX(VehicleCategoryID) from VehicleCategory
		END
	set @vehicleCatId=@vehicleCatId+1;
insert into VehicleCategory(VehicleCategoryID,VehicleCategoryName,UserID) values(@vehicleCatId,@vehicleCategoryName,@userId)
select @vehicleCatId
END
GO



/****** Object:  StoredProcedure [dbo].[createVehiclePool]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[createVehiclePool] @availability BIT, @locationID INTEGER, @vehicleID INTEGER, @amount INTEGER
as 
Begin
    if NOT EXISTS (select * FROM VehiclePool WHERE VehicleID=@vehicleID)
    BEGIN
        INSERT INTO VehiclePool ([Availability], LocationID, VehicleID, Amount) VALUES(@availability,@locationID,@vehicleID,@amount)
    END
    ELSE
    BEGIN
        UPDATE VehiclePool SET Availability=1 WHERE VehicleID = @vehicleID
    END
End

GO



/****** Object:  StoredProcedure [dbo].[getBookingByUserID]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[getBookingByUserID]  @UserID INTEGER
As
    SELECT * From Bookings WHERE UserID=@UserID;

GO



/****** Object:  StoredProcedure [dbo].[InsertLocation]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InsertLocation] @Region char(1), @UserID INTEGER
AS
    INSERT INTO dbo.[Location] (Region, UserID, State) VALUES (@Region, @UserID, dbo.getStateByCity(@Region))

GO



/****** Object:  StoredProcedure [dbo].[InsertVehicleCategory]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InsertVehicleCategory] @VehicleCategoryName nvarchar(250), @UserID INTEGER
AS
    INSERT INTO dbo.[VehicleCategory] (VehicleCategoryName, UserID) VALUES (@VehicleCategoryName, @UserID)

GO



/****** Object:  StoredProcedure [dbo].[registerUser]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[registerUser] @username nvarchar(250),@password nvarchar(250),@userId int, @token nvarchar(250) output, @error nvarchar(250) output
As
Begin
	if isnull(@username,'') = ''
	begin
		set @error = 'username invalid';
	end
	else if isnull(@password,'') = ''
	begin
		set @error = 'password invalid';
	end
	else if isnull(@userId,'') = ''
	begin
		set @error = 'userId invalid'
	end
	set @token = newid();
	open symmetric key userAuth_sm decryption by certificate userPass;
	insert into UserAuthentication(UserID,username,Token, password, LastLogin) values(@userId,@username,@token,dbo.encryptPass(@password), getdate() );
End
GO




/****** Object:  StoredProcedure [dbo].[removePaymentMethod]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[removePaymentMethod] @paymentMethodID int, @result nvarchar(250) output, @error NVARCHAR(250) output
As
Begin
	if isnull(@paymentMethodID,'') = ''
	begin
		set @error = 'paymentMethod invalid';
	end
	DELETE FROM PaymentMethods WHERE PaymentMethodID=@paymentMethodID;
    set @result = 'paymentMethod Deleted'
End
GO




/****** Object:  StoredProcedure [dbo].[removeVehicle]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[removeVehicle] @vehicleID int, @result nvarchar(250) output, @error NVARCHAR(250) output
As
Begin
	if isnull(@vehicleID,'') = ''
	begin
		set @error = 'vehicleID invalid';
	end
	UPDATE VehiclePool SET  Availability=0 WHERE VehicleID=@vehicleID
    set @result = 'vehicle Deleted from Pool'
End
GO




/****** Object:  StoredProcedure [dbo].[updatePassword]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updatePassword] @userId int, @password nvarchar(250), @result nvarchar(250) output, @error NVARCHAR(250) output
As
Begin
	if isnull(@password,'') = ''
	begin
		set @error = 'password invalid';
	end
	set @result = newid();
	open symmetric key userAuth_sm decryption by certificate userPass;
	UPDATE UserAuthentication SET [password] = dbo.encryptPass(@password) WHERE UserID=@userId;
End
GO



/****** Object:  StoredProcedure [dbo].[updateUser]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateUser] 
@userID int,
@FirstName nvarchar(100),
@LastName nvarchar(100),
@birthdate datetime2 ,
@Gender nvarchar(10),
@PhoneNumber nvarchar(10),
@SSN nvarchar(9) NULL,
@Type nvarchar(10),
@username nvarchar(250), 
@password nvarchar(250),
@role nvarchar(50),
@workEmail nvarchar(50),
@ein nvarchar(50),
@LicenceNo int, 
@expiryDate datetime2, 
@designation nvarchar(50), 
@fax nvarchar(50), 
@businessID int,
@updateduUserID int output,
@token nvarchar(250) output,
@errorMessage nvarchar(100) output
 AS
Begin
/*
Insert into Users values('Jay', 'a','98/02/2019' ,'Male','8901231234','123456789','Customer','jay','jay','employee','ivanrvf@gmail.com','123',0912345678, '10/09/2019', 'intern', '908098909', 12345)
*/
	If @FirstName like '[0-9]+' or isnull(@FirstName,'') = '' or @LastName like '[0-9]+' or isnull(@LastName,'') = ''
	Begin
		set @errorMessage = 'Invalid FirstName';
	end
	else if isnull(@birthdate,'') = ''
	Begin
		set @errorMessage = 'Invalid Birthdate';
	end
	else if isnull(@username,'') = '' or isnull(@password,'') = ''
	Begin
		set @errorMessage = 'Invalid Username/Password';
	end
	else if isnull(@SSN,'') = ''
	Begin
		set @errorMessage = ' Invalid SSN ';
	end
	else if isnull(@Type,'') = ''
	Begin
		set @errorMessage = 'Type is required'
	end
	else
	Begin
		UPDATE Users SET FirstName = @FirstName, LastName = @LastName, Birthdate = @birthdate, Gender = @Gender, PhoneNumber=@PhoneNumber,SSN=@SSN,Type=@Type WHERE UserID=@userID
		set @updateduUserID = SCOPE_IDENTITY();
		if @Type = 'Admin'
		Begin
			UPDATE [Admin] SET Role= @role, WorkEmail= @workemail, EIN = @ein WHERE UserID=@userID
		end
		else if @Type = 'Customer'
		begin
			UPDATE [Customer] SET LicenceNumber= @LicenceNo, ExpiryDate= @expiryDate, EIN=@ein,Designation= @designation,WorkEmail= @workEmail,Fax= @fax,BusinessID= @businessID WHERE UserID=@userID;
		end
		
	end
End
GO



/****** Object:  StoredProcedure [dbo].[userlogin]    Script Date: 4/21/2019 7:16:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[userlogin] 
@username nvarchar(250),
@password nvarchar(250),
@token nvarchar(250) output
as
Begin
	set @token = newid();
	open symmetric key userAuth_sm decryption by certificate userPass;
	update UserAuthentication set Token = @token, LastLogin = getdate() 
	where username = @username and dbo.decryptPass([password]) = @password;
end

GO

