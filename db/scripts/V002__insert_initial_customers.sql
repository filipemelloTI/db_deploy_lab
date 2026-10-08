-- DML: seed initial customers
BEGIN TRAN;

INSERT INTO dbo.customer (full_name, email)
VALUES (N'Alice Johnson', N'alice.johnson@example.com'),
       (N'Rahul Sharma',  N'rahul.sharma@example.com');

COMMIT;
