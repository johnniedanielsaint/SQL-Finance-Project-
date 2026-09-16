-- ============================================================
-- Personal Finance Analysis — SQL Portfolio Project
-- Database: finance.db (SQLite)
-- Data covers Jan 2021 - Feb 2024 (38 months)
-- ============================================================


-- ============================================================
-- SECTION 1: DATA EXPLORATION
-- ============================================================

-- 1.1 What date range and how many months are in the dataset?
SELECT
    MIN(txn_date) AS first_month,
    MAX(txn_date) AS last_month,
    COUNT(DISTINCT txn_date) AS months_covered
FROM finance_transactions;

-- 1.2 What categories exist under each type, and how much do they total?
SELECT
    type,
    category,
    COUNT(*)      AS months_recorded,
    SUM(amount)   AS total_amount,
    ROUND(AVG(amount), 2) AS avg_monthly_amount
FROM finance_transactions
GROUP BY type, category
ORDER BY type, total_amount DESC;


-- ============================================================
-- SECTION 2: CORE MONTHLY AGGREGATIONS
-- ============================================================

-- 2.1 Monthly income, expense, savings side by side (pivot with CASE)
SELECT
    txn_date,
    SUM(CASE WHEN type = 'Income'  THEN amount ELSE 0 END) AS income,
    SUM(CASE WHEN type = 'Expense' THEN amount ELSE 0 END) AS expense,
    SUM(CASE WHEN type = 'Savings' THEN amount ELSE 0 END) AS savings
FROM finance_transactions
GROUP BY txn_date
ORDER BY txn_date;

-- 2.2 Net cash flow per month (income left after expenses & savings)
SELECT
    txn_date,
    SUM(CASE WHEN type = 'Income'  THEN amount ELSE 0 END)
      - SUM(CASE WHEN type = 'Expense' THEN amount ELSE 0 END)
      - SUM(CASE WHEN type = 'Savings' THEN amount ELSE 0 END) AS net_leftover
FROM finance_transactions
GROUP BY txn_date
ORDER BY txn_date;

-- 2.3 Yearly totals by type
SELECT
    strftime('%Y', txn_date) AS year,
    type,
    SUM(amount) AS total_amount
FROM finance_transactions
GROUP BY year, type
ORDER BY year, type;


-- ============================================================
-- SECTION 3: CATEGORY-LEVEL ANALYSIS
-- ============================================================

-- 3.1 Top 5 expense categories by total spend over the full period
SELECT
    category,
    SUM(amount) AS total_spent
FROM finance_transactions
WHERE type = 'Expense'
GROUP BY category
ORDER BY total_spent DESC
LIMIT 5;

-- 3.2 Each expense category's share (%) of total expenses (window function)
SELECT
    category,
    SUM(amount) AS total_spent,
    ROUND(100.0 * SUM(amount) / SUM(SUM(amount)) OVER (), 2) AS pct_of_total_expense
FROM finance_transactions
WHERE type = 'Expense'
GROUP BY category
ORDER BY total_spent DESC;

-- 3.3 Which savings vehicle received the most money?
SELECT
    category,
    SUM(amount) AS total_saved
FROM finance_transactions
WHERE type = 'Savings'
GROUP BY category
ORDER BY total_saved DESC;


-- ============================================================
-- SECTION 4: TREND ANALYSIS (CTEs + WINDOW FUNCTIONS)
-- ============================================================

-- 4.1 Month-over-month expense growth %
WITH monthly_expense AS (
    SELECT txn_date, SUM(amount) AS expense
    FROM finance_transactions
    WHERE type = 'Expense'
    GROUP BY txn_date
)
SELECT
    txn_date,
    expense,
    LAG(expense) OVER (ORDER BY txn_date) AS prev_month_expense,
    ROUND(
        100.0 * (expense - LAG(expense) OVER (ORDER BY txn_date))
        / LAG(expense) OVER (ORDER BY txn_date), 2
    ) AS mom_growth_pct
FROM monthly_expense
ORDER BY txn_date;

-- 4.2 Rolling 3-month average expense (smooths out monthly noise)
WITH monthly_expense AS (
    SELECT txn_date, SUM(amount) AS expense
    FROM finance_transactions
    WHERE type = 'Expense'
    GROUP BY txn_date
)
SELECT
    txn_date,
    expense,
    ROUND(AVG(expense) OVER (
        ORDER BY txn_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3mo_avg_expense
FROM monthly_expense
ORDER BY txn_date;

-- 4.3 Cumulative (running) savings balance over time
WITH monthly_savings AS (
    SELECT txn_date, SUM(amount) AS savings
    FROM finance_transactions
    WHERE type = 'Savings'
    GROUP BY txn_date
)
SELECT
    txn_date,
    savings,
    SUM(savings) OVER (ORDER BY txn_date) AS cumulative_savings
FROM monthly_savings
ORDER BY txn_date;

-- 4.4 Rank months by total expense, highest first
WITH monthly_expense AS (
    SELECT txn_date, SUM(amount) AS expense
    FROM finance_transactions
    WHERE type = 'Expense'
    GROUP BY txn_date
)
SELECT
    txn_date,
    expense,
    RANK() OVER (ORDER BY expense DESC) AS expense_rank
FROM monthly_expense
ORDER BY expense_rank
LIMIT 10;


-- ============================================================
-- SECTION 5: SAVINGS RATE vs. TARGET
-- ============================================================

-- 5.1 Actual savings rate per month vs. the household's own target
WITH monthly AS (
    SELECT
        txn_date,
        SUM(CASE WHEN type = 'Income'  THEN amount ELSE 0 END) AS income,
        SUM(CASE WHEN type = 'Savings' THEN amount ELSE 0 END) AS savings
    FROM finance_transactions
    GROUP BY txn_date
)
SELECT
    m.txn_date,
    m.income,
    m.savings,
    ROUND(m.savings * 1.0 / m.income, 3) AS actual_savings_rate,
    t.target_rate,
    CASE
        WHEN m.savings * 1.0 / m.income >= t.target_rate THEN 'Met'
        ELSE 'Missed'
    END AS target_status
FROM monthly m
JOIN savings_target t ON t.txn_date = m.txn_date
ORDER BY m.txn_date;

-- 5.2 What % of months hit the savings target?
WITH monthly AS (
    SELECT
        txn_date,
        SUM(CASE WHEN type = 'Income'  THEN amount ELSE 0 END) AS income,
        SUM(CASE WHEN type = 'Savings' THEN amount ELSE 0 END) AS savings
    FROM finance_transactions
    GROUP BY txn_date
),
compared AS (
    SELECT
        m.txn_date,
        CASE WHEN m.savings * 1.0 / m.income >= t.target_rate THEN 1 ELSE 0 END AS met_target
    FROM monthly m
    JOIN savings_target t ON t.txn_date = m.txn_date
)
SELECT
    SUM(met_target)                              AS months_met_target,
    COUNT(*)                                      AS total_months,
    ROUND(100.0 * SUM(met_target) / COUNT(*), 1)  AS pct_months_met_target
FROM compared;


-- ============================================================
-- SECTION 6: DEEPER / DERIVED INSIGHTS
-- ============================================================

-- 6.1 Best and worst month by net leftover cash (subquery)
SELECT txn_date, net_leftover, 'Highest' AS label
FROM (
    SELECT txn_date,
           SUM(CASE WHEN type='Income' THEN amount ELSE 0 END)
         - SUM(CASE WHEN type='Expense' THEN amount ELSE 0 END)
         - SUM(CASE WHEN type='Savings' THEN amount ELSE 0 END) AS net_leftover
    FROM finance_transactions GROUP BY txn_date
)
ORDER BY net_leftover DESC LIMIT 1;

-- 6.2 Which expense category grew the most from 2021 to 2023 (full years)?
WITH yearly_cat AS (
    SELECT
        strftime('%Y', txn_date) AS year,
        category,
        SUM(amount) AS total_spent
    FROM finance_transactions
    WHERE type = 'Expense' AND strftime('%Y', txn_date) IN ('2021', '2023')
    GROUP BY year, category
)
SELECT
    y2021.category,
    y2021.total_spent AS spend_2021,
    y2023.total_spent AS spend_2023,
    ROUND(100.0 * (y2023.total_spent - y2021.total_spent) / y2021.total_spent, 1) AS pct_growth
FROM yearly_cat y2021
JOIN yearly_cat y2023
  ON y2021.category = y2023.category AND y2021.year = '2021' AND y2023.year = '2023'
ORDER BY pct_growth DESC;

-- 6.3 Income growth: salary increases over time (detect raises)
SELECT
    txn_date,
    amount AS salary,
    LAG(amount) OVER (ORDER BY txn_date) AS prev_salary,
    CASE WHEN amount != LAG(amount) OVER (ORDER BY txn_date) THEN 'Changed' ELSE '' END AS flag
FROM finance_transactions
WHERE type = 'Income' AND category = 'Salary'
ORDER BY txn_date;
