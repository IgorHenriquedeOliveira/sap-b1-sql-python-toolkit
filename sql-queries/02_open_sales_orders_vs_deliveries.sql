/*
 * 02_open_sales_orders_vs_deliveries.sql
 * SAP Business One (SQL Server / T-SQL) - READ-ONLY query
 *
 * Purpose : Open sales orders, delivered vs. open quantities, days overdue and delivery SLA status.
 * Tables  : ORDR (Sales Order header), RDR1 (Sales Order rows), OCRD (Business Partners)
 *
 * Author  : Igor Henrique de Oliveira
 * LinkedIn: https://linkedin.com/in/igor-henrique-de-oliveira
 * GitHub  : https://github.com/IgorHenriquedeOliveira
 *
 * Educational example only. SELECT statements only - no data is modified.
 */

SELECT
    T0.DocNum                                        AS OrderNumber,
    T0.DocDate                                       AS OrderDate,
    T0.CardCode,
    T2.CardName,
    T1.LineNum,
    T1.ItemCode,
    T1.Dscription                                    AS ItemDescription,
    T1.WhsCode,
    T1.Quantity                                      AS OrderedQty,
    (T1.Quantity - T1.OpenQty)                       AS DeliveredQty,
    T1.OpenQty                                       AS OpenQty,
    T1.ShipDate                                      AS PromisedDate,
    CASE
        WHEN T1.ShipDate < CAST(GETDATE() AS DATE)
            THEN DATEDIFF(DAY, T1.ShipDate, CAST(GETDATE() AS DATE))
        ELSE 0
    END                                              AS DaysOverdue,
    CASE
        WHEN T1.ShipDate IS NULL                                        THEN 'NO PROMISED DATE'
        WHEN T1.ShipDate < CAST(GETDATE() AS DATE)                      THEN 'LATE'
        WHEN T1.ShipDate = CAST(GETDATE() AS DATE)                      THEN 'DUE TODAY'
        WHEN DATEDIFF(DAY, CAST(GETDATE() AS DATE), T1.ShipDate) <= 3   THEN 'AT RISK'
        ELSE 'ON TRACK'
    END                                              AS DeliverySlaStatus
FROM ORDR T0
INNER JOIN RDR1 T1 ON T1.DocEntry = T0.DocEntry
INNER JOIN OCRD T2 ON T2.CardCode = T0.CardCode
WHERE T0.DocStatus  = 'O'
  AND T0.CANCELED   = 'N'
  AND T1.LineStatus = 'O'
  AND T1.OpenQty    > 0
ORDER BY
    DaysOverdue DESC,
    T1.ShipDate ASC,
    T0.DocNum;
