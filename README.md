# Personal Finance SQL Analysis

A SQL portfolio project that turns a 38-month personal finance ledger
(Jan 2021 – Feb 2024) into a queryable relational database and answers
a set of realistic budgeting questions with SQL alone: aggregation,
CTEs, window functions, and joins.

## Project overview

The source data (`Finance_Dataset.xlsx`) arrived in a **wide** format:
one row per category, one column per month. That layout is common in
spreadsheets but unusable for relational analysis, so step one was an
ETL pass to **unpivot ("melt") it into a tidy long format**, one row
per (date, category, amount), before loading it into SQLite.

**Pipeline:** `xlsx (wide)` → `pandas melt → tidy CSV` → `SQLite (normalized schema)` → `SQL analysis`

## Files in this project

| File | Purpose |
|---|---|
| `schema.sql` | Table definitions (DDL) for the two-table schema |
| `finance_long.csv` | The cleaned, tidy (long-format) dataset used to load the DB |
| `finance.db` | The finished SQLite database; open it directly and run the queries |
| `queries.sql` | 17 analysis queries, organized from basic to advanced |

## Schema

**`finance_transactions`**: every income, expense, and savings entry
| column | type | notes |
|---|---|---|
| id | INTEGER PK | |
| txn_date | DATE | first of the month |
| type | TEXT | `Income`, `Expense`, or `Savings` |
| category | TEXT | e.g. `Salary`, `House Rent`, `Mutual funds` |
| amount | REAL | |

**`savings_target`**: the household's own monthly savings goal, kept
separate since it's a *rate* (e.g. 0.25 = 25% of income), not a
transaction:
| column | type |
|---|---|
| txn_date | DATE PK |
| target_rate | REAL |

Two tables, joined on `txn_date`, keep the design simple while still
requiring a real join for the savings-vs-target analysis.

## What the queries cover

1. **Exploration**: date range, category inventory
2. **Core aggregation**: monthly income/expense/savings pivot (`CASE WHEN`), net cash flow, yearly totals
3. **Category analysis**: top expense categories, each category's % share of spend (window function `SUM() OVER ()`)
4. **Trend analysis**: month-over-month growth (`LAG`), 3-month rolling average, cumulative savings (`SUM() OVER (ORDER BY ...)`), ranking months by spend (`RANK()`)
5. **Savings rate vs. target**: actual savings rate per month joined against the stated goal, % of months the target was hit
6. **Derived insights**: best/worst cash-flow month, fastest-growing expense category (2021 vs 2023), salary-change detection

## Key findings

- Across the full period: **₹27.9L income**, **₹12.7L expenses**, **₹17.9L saved**.
- **House Rent** is the single largest expense category (₹5.08L total), followed by **Groceries & Food** and **EMIs**.
- The household **met or exceeded its stated savings target in every one of the 38 months**. The target rate itself stepped up from 25% (2021) to 30% (2022 onward), and actual savings tracked well above both.
- **Health** spend grew the fastest of any category, up **~208%** from 2021 to 2023, followed by **EMIs (+177%)**; worth flagging as the categories most eroding future savings capacity.
- Salary moved through five distinct steps over the period (₹60,000 → ₹66,000 → ₹70,000 → ₹75,000 → ₹75,600), each detectable directly from the transaction data via a `LAG()` window function rather than being hard-coded.
- One data-quality note surfaced during EDA: in several months, `Expense + Savings` slightly exceeds `Income`, implying either an untracked income source or that "Savings" here includes rollover/pre-existing balances rather than only *new* money. Worth calling out in a real analysis rather than silently ignoring.

## How to explore it yourself

Any SQLite client works, e.g. [DB Browser for SQLite](https://sqlitebrowser.org/)
(GUI) or the `sqlite3` CLI:

```bash
sqlite3 finance.db
.read queries.sql
```

Or in Python:
```python
import sqlite3, pandas as pd
conn = sqlite3.connect("finance.db")
pd.read_sql("SELECT * FROM finance_transactions LIMIT 10", conn)
```

## Skills demonstrated

- Data cleaning / reshaping (wide → long)
- Relational schema design
- `GROUP BY` aggregation, `CASE WHEN` pivoting
- CTEs (`WITH`)
- Window functions: `LAG`, `RANK`, running `SUM() OVER`, `AVG() OVER (ROWS BETWEEN ...)`
- Joins across normalized tables
- Deriving business insights from raw transactional data
