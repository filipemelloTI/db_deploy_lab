-- Intentionally broken script to test the failure path
BEGIN TRAN;

CREATE TABL dbo.this_will_fail (id INT);

COMMIT;