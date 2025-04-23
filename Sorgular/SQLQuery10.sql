DECLARE @kullanici_girdisi NVARCHAR(100) = 'Nintendo';
DECLARE @sql NVARCHAR(MAX) = N'SELECT * FROM vgsales WHERE Publisher = @pub';

EXEC sp_executesql @sql, N'@pub NVARCHAR(100)', @pub = @kullanici_girdisi;
