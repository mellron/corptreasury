CREATE FUNCTION dbo.SplitString
(
    @DelimitedString NVARCHAR(MAX),
    @Delimiter CHAR(1)
)
RETURNS @Result TABLE (Value NVARCHAR(MAX))
AS
BEGIN
    DECLARE @StartIndex INT = 1
    DECLARE @EndIndex INT

    WHILE CHARINDEX(@Delimiter, @DelimitedString, @StartIndex) > 0
    BEGIN
        SET @EndIndex = CHARINDEX(@Delimiter, @DelimitedString, @StartIndex)
        INSERT INTO @Result (Value)
        VALUES (SUBSTRING(@DelimitedString, @StartIndex, @EndIndex - @StartIndex))

        SET @StartIndex = @EndIndex + 1
    END

    -- Add the last part of the string (or the entire string if no delimiter was found)
    IF @StartIndex <= LEN(@DelimitedString)
    BEGIN
        INSERT INTO @Result (Value)
        VALUES (SUBSTRING(@DelimitedString, @StartIndex, LEN(@DelimitedString) - @StartIndex + 1))
    END

    RETURN
END
