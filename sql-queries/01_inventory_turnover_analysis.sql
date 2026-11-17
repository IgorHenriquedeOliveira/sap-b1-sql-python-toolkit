/*
 * 01_inventory_turnover_analysis.sql
 * SAP Business One (SQL Server / T-SQL) - READ-ONLY query
 *
 * Purpose : Stock availability, minimum stock level and inventory valuation per warehouse.
 * Tables  : OITM (Items), OITW (Item stock per warehouse), OWHS (Warehouses)
 * Formula : Available = OnHand - IsCommited + OnOrder
 *
 * Author  : Igor Henrique de Oliveira
 * LinkedIn: https://linkedin.com/in/igor-henrique-de-oliveira
 * GitHub  : https://github.com/IgorHenriquedeOliveira
 *
 * Educational example only. SELECT statements only - no data is modified.
 */

SELECT
    T0.ItemCode,
    T0.ItemName,
    T2.WhsCode,
    T2.WhsName,
    T1.OnHand,
    T1.IsCommited                                AS Committed,
    T1.OnOrder,
    (T1.OnHand - T1.IsCommited + T1.OnOrder)     AS Available,
    T1.MinStock,
    CASE
        WHEN (T1.OnHand - T1.IsCommited + T1.OnOrder) < T1.MinStock THEN 'BELOW MINIMUM'
        WHEN T1.OnHand <= 0                                         THEN 'OUT OF STOCK'
        ELSE 'OK'
    END                                          AS StockStatus,
    T1.AvgPrice,
    (T1.OnHand * T1.AvgPrice)                    AS StockValue
FROM OITM T0
INNER JOIN OITW T1 ON T1.ItemCode = T0.ItemCode
INNER JOIN OWHS T2 ON T2.WhsCode  = T1.WhsCode
WHERE T0.InvntItem = 'Y'
  AND T0.frozenFor = 'N'
ORDER BY
    T2.WhsCode,
    Available ASC,
    T0.ItemCode;
