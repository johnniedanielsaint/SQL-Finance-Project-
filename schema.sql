-- ============================================================
-- Personal Finance Tracker — Database Schema
-- ============================================================
-- Source: Finance_Dataset.xlsx (wide-format monthly ledger,
-- Jan 2021 - Feb 2024), reshaped into a tidy/long format and
-- normalized into two tables.

DROP TABLE IF EXISTS finance_transactions;
DROP TABLE IF EXISTS savings_target;

-- Every recorded money movement: income received, money moved
-- into savings/investment vehicles, or money spent.
CREATE TABLE finance_transactions (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    txn_date  DATE    NOT NULL,                 -- first of each month
    type      TEXT    NOT NULL CHECK (type IN ('Income','Expense','Savings')),
    category  TEXT    NOT NULL,                 -- e.g. Salary, House Rent, Mutual funds
    amount    REAL    NOT NULL
);

-- The household's target savings rate (as a % of income) for
-- each month — used to compare planned vs. actual behavior.
CREATE TABLE savings_target (
    txn_date     DATE PRIMARY KEY,
    target_rate  REAL NOT NULL                  -- e.g. 0.25 = 25%
);

CREATE INDEX idx_txn_date ON finance_transactions(txn_date);
CREATE INDEX idx_txn_type ON finance_transactions(type);
CREATE INDEX idx_txn_category ON finance_transactions(category);
