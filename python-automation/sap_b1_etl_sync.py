"""
sap_b1_etl_sync.py

Educational ETL example for SAP Business One (SQL Server).
Extracts A/R Invoices (OINV) updated in the last N days (default: 30) and writes them to a CSV file.

Safety notes:
  * Read-only: a single parameterized SELECT, connection opened with ApplicationIntent=ReadOnly.
  * No credentials in code: every setting comes from environment variables (see below).
  * Generic placeholder company database: SBO_DEMO_COMPANY.

Environment variables:
  SBO_SQL_DRIVER    ODBC driver name        (default: ODBC Driver 18 for SQL Server)
  SBO_SQL_SERVER    SQL Server host         (default: localhost)
  SBO_DEMO_COMPANY  Company database name   (default: SBO_DEMO_COMPANY)
  SBO_SQL_USER      SQL login               (optional; Windows authentication is used when empty)
  SBO_SQL_PASSWORD  SQL password            (optional)
  SBO_LOOKBACK_DAYS Days to look back       (default: 30)
  SBO_OUTPUT_DIR    CSV output directory    (default: output)

Author  : Igor Henrique de Oliveira
LinkedIn: https://linkedin.com/in/igor-henrique-de-oliveira
GitHub  : https://github.com/IgorHenriquedeOliveira
"""

import logging
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd
import pyodbc

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)
logger = logging.getLogger("sap_b1_etl_sync")

INVOICE_QUERY = """
SELECT
    T0.DocEntry,
    T0.DocNum,
    T0.DocDate,
    T0.DocDueDate,
    T0.CardCode,
    T0.CardName,
    T0.DocCur,
    T0.DocTotal,
    T0.VatSum,
    T0.PaidToDate,
    T0.UpdateDate
FROM OINV T0
WHERE T0.CANCELED = 'N'
  AND T0.UpdateDate >= ?
ORDER BY T0.DocDate, T0.DocNum;
"""


def build_connection_string() -> str:
    """Build a read-only ODBC connection string from environment variables."""
    driver = os.getenv("SBO_SQL_DRIVER", "ODBC Driver 18 for SQL Server")
    server = os.getenv("SBO_SQL_SERVER", "localhost")
    database = os.getenv("SBO_DEMO_COMPANY", "SBO_DEMO_COMPANY")
    user = os.getenv("SBO_SQL_USER", "")
    password = os.getenv("SBO_SQL_PASSWORD", "")

    parts = [
        f"DRIVER={{{driver}}}",
        f"SERVER={server}",
        f"DATABASE={database}",
        "ApplicationIntent=ReadOnly",
        "Encrypt=yes",
        "TrustServerCertificate=yes",
    ]
    if user:
        parts.append(f"UID={user}")
        parts.append(f"PWD={password}")
    else:
        parts.append("Trusted_Connection=yes")
    return ";".join(parts)


def extract_invoices(connection_string: str, since: datetime) -> pd.DataFrame:
    """Run the read-only invoice query and return the result as a DataFrame."""
    logger.info("Extracting OINV rows updated since %s", since.date())
    with pyodbc.connect(connection_string, timeout=30) as connection:
        cursor = connection.cursor()
        cursor.execute(INVOICE_QUERY, since.date())
        columns = [column[0] for column in cursor.description]
        rows = [tuple(row) for row in cursor.fetchall()]
    dataframe = pd.DataFrame.from_records(rows, columns=columns)
    logger.info("Extracted %d invoice rows", len(dataframe))
    return dataframe


def transform_invoices(dataframe: pd.DataFrame) -> pd.DataFrame:
    """Light cleanup: normalize dates and add an open balance column."""
    if dataframe.empty:
        return dataframe
    for column in ("DocDate", "DocDueDate", "UpdateDate"):
        dataframe[column] = pd.to_datetime(dataframe[column]).dt.date
    dataframe["OpenBalance"] = dataframe["DocTotal"] - dataframe["PaidToDate"]
    return dataframe


def load_to_csv(dataframe: pd.DataFrame, output_dir: Path) -> Path:
    """Write the DataFrame to a timestamped CSV file inside output_dir."""
    output_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    target = output_dir / f"oinv_last_30_days_{timestamp}.csv"
    dataframe.to_csv(target, index=False, encoding="utf-8-sig")
    logger.info("CSV written to %s", target)
    return target


def main() -> int:
    lookback_days = int(os.getenv("SBO_LOOKBACK_DAYS", "30"))
    output_dir = Path(os.getenv("SBO_OUTPUT_DIR", "output"))
    since = datetime.now() - timedelta(days=lookback_days)

    try:
        invoices = extract_invoices(build_connection_string(), since)
        invoices = transform_invoices(invoices)
        load_to_csv(invoices, output_dir)
    except pyodbc.Error:
        logger.exception("Database error while extracting invoices")
        return 1
    except Exception:
        logger.exception("Unexpected error in the ETL pipeline")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
