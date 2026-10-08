-- DDL: create the customer table
BEGIN TRAN;

CREATE TABLE dbo.customer (
    customer_id  INT IDENTITY(1,1) PRIMARY KEY,
    full_name    NVARCHAR(150) NOT NULL,
    email        NVARCHAR(200) NOT NULL UNIQUE,
    created_on   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);

COMMIT;
