-- DDL: add status column to customer
BEGIN TRAN;

ALTER TABLE dbo.customer ADD status NVARCHAR(20) NOT NULL
    CONSTRAINT DF_customer_status DEFAULT N'ACTIVE';

COMMIT;