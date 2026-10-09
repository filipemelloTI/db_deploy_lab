-- DDL: create the customer order table
BEGIN TRAN;

CREATE TABLE dbo.customer_order (
    order_id     INT IDENTITY(1,1) PRIMARY KEY,
    customer_id  INT           NOT NULL
                 REFERENCES dbo.customer (customer_id),
    order_date   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    total_amount DECIMAL(10,2) NOT NULL
);

COMMIT;