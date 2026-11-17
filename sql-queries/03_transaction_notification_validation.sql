/*
 * 03_transaction_notification_validation.sql
 * SAP Business One (SQL Server / T-SQL) - validation block for SBO_SP_TransactionNotification
 *
 * Purpose : Block Sales Orders (object type 17) that
 *           (1) have rows without a Cost Center (RDR1.OcrCode), or
 *           (2) push the customer above its credit limit (OCRD.CreditLine).
 * Tables  : ORDR (Sales Order header), RDR1 (Sales Order rows), OCRD (Business Partners)
 *
 * Author  : Igor Henrique de Oliveira
 * LinkedIn: https://linkedin.com/in/igor-henrique-de-oliveira
 * GitHub  : https://github.com/IgorHenriquedeOliveira/sap-b1-sql-python-toolkit
 *
 * Educational example only. Paste the block below inside the stored procedure
 * SBO_SP_TransactionNotification of a TEST company database, after the standard
 * parameters and the @error / @error_message variables have been declared:
 *
 *   @object_type              nvarchar(20)   -- SAP B1 object type, '17' = Sales Order
 *   @transaction_type         nchar(1)       -- 'A' = Add, 'U' = Update, 'D' = Delete, 'C' = Cancel
 *   @list_of_cols_val_tab_del nvarchar(255)  -- key value(s): DocEntry for marketing documents
 *   @error                    int
 *   @error_message            nvarchar(200)
 *
 * The block only reads data (SELECT / EXISTS) and sets @error and @error_message.
 * Simplified credit rule: current balance + order total must not exceed CreditLine.
 */

-- ---------------------------------------------------------------------------
-- Validation block: Sales Order (object type 17)
-- ---------------------------------------------------------------------------
IF @object_type = '17' AND @transaction_type IN ('A', 'U')
BEGIN
    DECLARE @DocEntry INT = CAST(@list_of_cols_val_tab_del AS INT);

    -- Rule 1: every row must have a Cost Center (OcrCode)
    IF EXISTS (
        SELECT 1
        FROM RDR1 T1
        WHERE T1.DocEntry = @DocEntry
          AND (T1.OcrCode IS NULL OR LTRIM(RTRIM(T1.OcrCode)) = '')
    )
    BEGIN
        SET @error = 17001;
        SET @error_message = N'Sales Order blocked: all rows must have a Cost Center (OcrCode).';
    END

    -- Rule 2: customer credit limit (only checked when Rule 1 passed)
    IF @error = 0
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM ORDR T0
            INNER JOIN OCRD T2 ON T2.CardCode = T0.CardCode
            WHERE T0.DocEntry  = @DocEntry
              AND T2.CreditLine > 0
              AND (T2.Balance + T0.DocTotal) > T2.CreditLine
        )
        BEGIN
            SET @error = 17002;
            SET @error_message = N'Sales Order blocked: customer credit limit (CreditLine) exceeded.';
        END
    END
END
