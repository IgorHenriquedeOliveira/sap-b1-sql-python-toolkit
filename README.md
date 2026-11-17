# SAP Business One SQL & Python Toolkit

Educational toolkit with read-only T-SQL queries and a Python ETL example for **SAP Business One** on **SQL Server**.
Built as a public technical portfolio project: no real data, no credentials and no destructive operations.

**Note:** all examples are fictional and meant for learning. Always test in a non-production (test) company database first.

## Contents

| Path | Description |
| --- | --- |
| `sql-queries/01_inventory_turnover_analysis.sql` | Stock availability (`OnHand - IsCommited + OnOrder`), minimum stock level and inventory valuation per warehouse. |
| `sql-queries/02_open_sales_orders_vs_deliveries.sql` | Open sales orders vs. deliveries, days overdue (`DATEDIFF`) and delivery SLA status. |
| `sql-queries/03_transaction_notification_validation.sql` | `SBO_SP_TransactionNotification` validation block for Sales Orders (object type `17`): blocks rows without Cost Center (`OcrCode`) and orders above the credit limit (`OCRD.CreditLine`). |
| `python-automation/sap_b1_etl_sync.py` | Python ETL: incremental extraction of A/R Invoices (`OINV`) from the last 30 days into a `.csv` file. |
| `requirements.txt` | Python dependencies (`pyodbc`, `pandas`). |

## SAP Business One tables used

| Table | Description |
| --- | --- |
| `OITM` | Item master data |
| `OITW` | Item stock per warehouse |
| `OWHS` | Warehouses |
| `ORDR` | Sales Orders (header) |
| `RDR1` | Sales Orders (rows) |
| `OCRD` | Business Partners (customers and vendors) |
| `OINV` | A/R Invoices (header) |

## Tech stack

| Area | Technology |
| --- | --- |
| ERP | SAP Business One |
| Database | Microsoft SQL Server (T-SQL) |
| Automation / ETL | Python 3.10+, `pyodbc`, `pandas` |
| Output | CSV |

## Getting started

### 1. Install the Python dependencies

```bash
pip install -r requirements.txt
```

### 2. Install an ODBC driver

Install a Microsoft ODBC Driver for SQL Server (for example, ODBC Driver 18).

### 3. Configure the environment variables

Use a **test** database and a **read-only** login:

```bash
export SBO_SQL_SERVER="localhost"
export SBO_DEMO_COMPANY="SBO_DEMO_COMPANY"
export SBO_SQL_USER="<your_readonly_user>"
export SBO_SQL_PASSWORD="<your_password>"
export SBO_LOOKBACK_DAYS="30"
```

### 4. Run the ETL example

```bash
python python-automation/sap_b1_etl_sync.py
```

The CSV file is written to the `output/` folder, which is ignored by Git.

## Safety principles

The queries in `sql-queries/01` and `02` are plain `SELECT` statements. The Python script opens the connection with `ApplicationIntent=ReadOnly`, runs one parameterized `SELECT` and reads every setting from environment variables, so no secrets are stored in the repository. The `.env` file, logs and generated output are listed in `.gitignore`.

The validation block in `sql-queries/03` only reads data and sets the `@error` and `@error_message` variables; review it carefully and test it in a test company before adopting any part of it.

## Author

**Igor Henrique de Oliveira**

LinkedIn: [linkedin.com/in/igor-henrique-de-oliveira](https://linkedin.com/in/igor-henrique-de-oliveira) | GitHub: [github.com/IgorHenriquedeOliveira](https://github.com/IgorHenriquedeOliveira)
