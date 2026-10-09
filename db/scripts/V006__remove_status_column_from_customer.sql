-- DDL: undo V005 (status column not approved for production)
BEGIN TRAN;

ALTER TABLE dbo.customer DROP CONSTRAINT DF_customer_status;
ALTER TABLE dbo.customer DROP COLUMN status;

COMMIT;