-- ====================================
-- PROJE 1: VERİTABANI PERFORMANS OPTİMİZASYONU
-- ====================================

-- DMV ile en yavaş sorguları bulma
SELECT TOP 10 
    qs.execution_count,
    qs.total_elapsed_time / qs.execution_count AS avg_time,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset 
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset END 
        - qs.statement_start_offset)/2)+1) AS query_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY avg_time DESC;

-- Sorgu istatistikleri ölçümü
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT Publisher, Platform, COUNT(*) AS OyunSayisi
FROM vgsales
GROUP BY Publisher, Platform
ORDER BY OyunSayisi DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- İndeks oluşturma
CREATE NONCLUSTERED INDEX idx_platform_genre ON vgsales (Platform, Genre);
CREATE NONCLUSTERED INDEX idx_global_sales ON vgsales (Global_Sales);
CREATE NONCLUSTERED INDEX idx_publisher_year ON vgsales (Publisher, Year);

-- İndeks silme örneği
-- DROP INDEX idx_platform_genre ON vgsales;

-- ====================================
-- PROJE 2: YEDEKLEME VE FELAKETTEN KURTARMA
-- ====================================

-- Recovery model ayarı
ALTER DATABASE TestDB SET RECOVERY FULL;

-- Tam yedek
BACKUP DATABASE TestDB TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.GOKSU\MSSQL\Backup\TestDB.bak';

-- Fark yedeği
BACKUP DATABASE TestDB TO DISK = 'C:\Yedekler\differential_backup.bak' WITH DIFFERENTIAL;

-- Log yedeği
BACKUP LOG TestDB TO DISK = 'C:\Yedekler\transaction_backup.bak';

-- Geri yükleme
USE master;
ALTER DATABASE TestDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE TestDB FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.GOKSU\MSSQL\Backup\TestDB.bak' WITH REPLACE;
ALTER DATABASE TestDB SET MULTI_USER;

-- Yedekten yeni veritabanı oluşturma
RESTORE FILELISTONLY FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.GOKSU\MSSQL\Backup\TestDB.bak';

RESTORE DATABASE TestDB_YedekKontrol
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.GOKSU\MSSQL\Backup\TestDB.bak'
WITH 
   MOVE 'TestDB' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.GOKSU\MSSQL\DATA\TestDB_YedekKontrol.mdf',
   MOVE 'TestDB_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.GOKSU\MSSQL\DATA\TestDB_YedekKontrol_log.ldf',
   REPLACE;

-- ====================================
-- PROJE 3: GÜVENLİK VE ERİŞİM KONTROLÜ
-- ====================================

-- Login ve kullanıcı oluşturma
CREATE LOGIN oyun_kullanicisi WITH PASSWORD = 'Guv3nlik!';
USE TestDB;
CREATE USER oyun_kullanicisi FOR LOGIN oyun_kullanicisi;
EXEC sp_addrolemember 'db_datareader', 'oyun_kullanicisi';

-- TDE ile şifreleme
USE master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'TdeAnaParola123!';
CREATE CERTIFICATE TdeCert WITH SUBJECT = 'TDE Sertifikasi';
USE TestDB;
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TdeCert;
ALTER DATABASE TestDB SET ENCRYPTION ON;

-- SQL Injection örneği (güvensiz)
DECLARE @kullanici_girdisi NVARCHAR(100);
SET @kullanici_girdisi = ''' OR ''1''=''1';
DECLARE @sql NVARCHAR(MAX);
SET @sql = 'SELECT * FROM vgsales WHERE Publisher = ''' + @kullanici_girdisi + '''';
EXEC(@sql);

-- SQL Injection güvenli çözüm
DECLARE @sql2 NVARCHAR(MAX);
DECLARE @gercek NVARCHAR(100) = 'Nintendo';
SET @sql2 = N'SELECT * FROM vgsales WHERE Publisher = @pub';
EXEC sp_executesql @sql2, N'@pub NVARCHAR(100)', @pub = @gercek;

-- Server Audit ve Audit Spec
USE master;
CREATE SERVER AUDIT GirisDenetimi TO FILE (FILEPATH = 'C:\Yedekler\AuditLogs\');
ALTER SERVER AUDIT GirisDenetimi WITH (STATE = ON);

USE TestDB;
CREATE DATABASE AUDIT SPECIFICATION VeriOkuDenetimi
FOR SERVER AUDIT GirisDenetimi
ADD (SELECT ON OBJECT::vgsales BY oyun_kullanicisi)
WITH (STATE = ON);

-- Audit loglarını okuma
SELECT * FROM sys.fn_get_audit_file('C:\Yedekler\AuditLogs\*.sqlaudit', DEFAULT, DEFAULT);
