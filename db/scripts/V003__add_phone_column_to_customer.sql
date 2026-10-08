-- DDL: add phone number to customer
BEGIN TRAN;

ALTER TABLE dbo.customer ADD phone_number NVARCHAR(30) NULL;

COMMIT;
