DECLARE @kullanici_girdisi NVARCHAR(100);
SET @kullanici_girdisi = ''' OR ''1''=''1';

DECLARE @sql NVARCHAR(MAX);
SET @sql = 'SELECT * FROM vgsales WHERE Publisher = ''' + @kullanici_girdisi + '''';
EXEC(@sql);
