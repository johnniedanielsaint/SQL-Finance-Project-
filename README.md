# FinanceDB

A SQL Server database for tracking company revenue, expenses, and
budget performance over time. Built for SQL Server Management Studio
(SSMS), starting from a finance spreadsheet export covering January
2022 through December 2024.

The project takes a flat transaction log and a flat budget list and
turns them into a normalized schema with a proper chart of accounts,
department classifications, and a set of views and stored procedures
for the reporting questions a finance team actually asks: monthly
profit and loss, budget vs actual, and top vendors by spend.

## What is in here

```
FinanceDB/
├── database/
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   ├── 03_create_indexes.sql
│   ├── 04_create_views.sql
│   └── 05_create_stored_procedures.sql
├── data/
│   ├── accounts.csv
│   ├── classifications.csv
│   ├── transactions.csv
│   └── budget.csv
├── scripts/
│   └── load_data.sql
├── docs/
│   ├── data_dictionary.md
│   ├── er_diagram.md
│   └── sample_queries.sql
└── README.md
```

## Schema

Four tables:

- **Accounts** : the chart of accounts, with a two-level rollup
  hierarchy (`Level1` / `Level2`) for statement-style reporting.
- **Classifications** : department codes: `G&A`, `S&M`, `R&D`, `CS`.
- **Transactions** :  every posted invoice, bill, deposit, journal
  entry, and expense. 1,389 rows.
- **Budget** : planned monthly amounts by account and department.
  1,229 rows.

See `docs/er_diagram.md` for the relationships and `docs/data_dictionary.md`
for a column by column breakdown of every table, view, and stored
procedure.

## Setting it up in SSMS

1. Open SSMS and connect to your SQL Server instance.
2. Open and run `database/01_create_database.sql`. This creates the
   `FinanceDB` database.
3. Run `database/02_create_tables.sql`, then `03_create_indexes.sql`,
   `04_create_views.sql`, and `05_create_stored_procedures.sql`, in
   that order.
4. Copy the `data` folder to a path the SQL Server service account can
   read (for example `C:\FinanceDB\data\`), and update the
   `@DataFolder` variable at the top of `scripts/load_data.sql` if you
   used a different path.
5. Run `scripts/load_data.sql`. It loads the four CSV files with
   `BULK INSERT` and prints a row count for each table so you can
   confirm the load worked.

If `BULK INSERT` is not available to you (some managed or restricted
SQL Server instances disable it), you can instead right-click each
table in SSMS's Object Explorer, choose **Import Flat File**, and
point it at the matching CSV.

## Example queries

`docs/sample_queries.sql` has working examples for each stored
procedure, plus a couple of plain SELECT statements against the
views. A few of the questions it answers:

- What was net income for a given month?
- How does 2024 spend compare to 2024 budget for Sales & Marketing?
- Who are the five vendors we spent the most with last year?
- Which accounts ran more than 15 percent over budget?

## Notes on the source data

The original spreadsheet stored account names with the account code
baked into the text (for example `40100 SaaS Revenue`). That has been
split apart here: `AccountCode` and `AccountName` are separate
columns, and the code lives only in `AccountCode`, so joins and
lookups do not need string parsing.

## License

MIT. See `LICENSE`.
