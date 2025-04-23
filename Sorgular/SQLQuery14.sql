SELECT *
FROM sys.fn_get_audit_file(
    'C:\Yedekler\AuditLogs\*.sqlaudit',  
    DEFAULT,  
    DEFAULT
);
