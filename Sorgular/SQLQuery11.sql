USE master;
GO

CREATE SERVER AUDIT GirisDenetimi
TO FILE (FILEPATH = 'C:\Yedekler\AuditLogs\');
