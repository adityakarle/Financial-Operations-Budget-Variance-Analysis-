-- =====================================================
-- Financial Operations & Budget Variance Analysis
-- SQL Analysis Queries
-- =====================================================


-- QUERY 1: Monthly Actual vs Budget by Department

WITH actual AS (
    SELECT
        d.department_name,
        DATE_TRUNC('month', t.date) AS month,
        ROUND(SUM(t.amount)::numeric, 2) AS actual_spend
    FROM transactions t
    JOIN departments d ON t.department_id = d.department_id
    WHERE t.status = 'Approved'
    GROUP BY d.department_name, DATE_TRUNC('month', t.date)
),
budget AS (
    SELECT
        d.department_name,
        b.month,
        ROUND(SUM(b.budgeted_amount)::numeric, 2) AS total_budget
    FROM budgets b
    JOIN departments d ON b.department_id = d.department_id
    GROUP BY d.department_name, b.month
)
SELECT
    a.department_name,
    a.month,
    a.actual_spend,
    b.total_budget,
    ROUND((a.actual_spend - b.total_budget)::numeric, 2) AS variance,
    ROUND(((a.actual_spend - b.total_budget) / NULLIF(b.total_budget, 0) * 100)::numeric, 1) AS variance_pct
FROM actual a
JOIN budget b ON a.department_name = b.department_name
             AND a.month = b.month
ORDER BY ABS(((a.actual_spend - b.total_budget) / NULLIF(b.total_budget, 0) * 100)) DESC;


-- QUERY 2: Departments with 15-20% Budget Deviation

WITH actual AS (
    SELECT
        d.department_name,
        DATE_TRUNC('month', t.date) AS month,
        ROUND(SUM(t.amount)::numeric, 2) AS actual_spend
    FROM transactions t
    JOIN departments d ON t.department_id = d.department_id
    WHERE t.status = 'Approved'
    GROUP BY d.department_name, DATE_TRUNC('month', t.date)
),
budget AS (
    SELECT
        d.department_name,
        b.month,
        ROUND(SUM(b.budgeted_amount)::numeric, 2) AS total_budget
    FROM budgets b
    JOIN departments d ON b.department_id = d.department_id
    GROUP BY d.department_name, b.month
)
SELECT
    a.department_name,
    a.month,
    a.actual_spend,
    b.total_budget,
    ROUND((a.actual_spend - b.total_budget)::numeric, 2) AS variance,
    ROUND(((a.actual_spend - b.total_budget) / NULLIF(b.total_budget, 0) * 100)::numeric, 1) AS variance_pct
FROM actual a
JOIN budget b ON a.department_name = b.department_name
             AND a.month = b.month
WHERE ABS(((a.actual_spend - b.total_budget) / NULLIF(b.total_budget, 0) * 100)) BETWEEN 15 AND 22
ORDER BY variance_pct;


-- QUERY 3: Top Spending Categories

SELECT
    c.category_name,
    COUNT(*)                          AS transaction_count,
    ROUND(SUM(t.amount)::numeric, 2)  AS total_spend,
    ROUND(AVG(t.amount)::numeric, 2)  AS avg_transaction,
    MIN(t.amount)                     AS min_amount,
    MAX(t.amount)                     AS max_amount
FROM transactions t
JOIN categories c ON t.category_id = c.category_id
WHERE t.status = 'Approved'
GROUP BY c.category_name
ORDER BY total_spend DESC;


-- QUERY 4: Quarterly Budget Summary

WITH actual AS (
    SELECT
        d.department_name,
        DATE_PART('year', t.date)    AS year,
        DATE_PART('quarter', t.date) AS quarter,
        ROUND(SUM(t.amount)::numeric, 2) AS actual_spend
    FROM transactions t
    JOIN departments d ON t.department_id = d.department_id
    WHERE t.status = 'Approved'
    GROUP BY d.department_name,
             DATE_PART('year', t.date),
             DATE_PART('quarter', t.date)
),
budget AS (
    SELECT
        d.department_name,
        DATE_PART('year', b.month)    AS year,
        DATE_PART('quarter', b.month) AS quarter,
        ROUND(SUM(b.budgeted_amount)::numeric, 2) AS total_budget
    FROM budgets b
    JOIN departments d ON b.department_id = d.department_id
    GROUP BY d.department_name,
             DATE_PART('year', b.month),
             DATE_PART('quarter', b.month)
)
SELECT
    a.department_name,
    a.year,
    a.quarter,
    a.actual_spend,
    b.total_budget,
    ROUND((a.actual_spend - b.total_budget)::numeric, 2) AS variance
FROM actual a
JOIN budget b ON a.department_name = b.department_name
             AND a.year = b.year
             AND a.quarter = b.quarter
ORDER BY a.year, a.quarter, a.department_name;


-- QUERY 5: Data Validation Checks

-- Check 1: Duplicate transaction IDs (should return 0 rows)
SELECT transaction_id, COUNT(*) AS count
FROM transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- Check 2: NULL or negative amounts (should return 0)
SELECT COUNT(*) AS problem_rows
FROM transactions
WHERE amount IS NULL OR amount <= 0;

-- Check 3: Orphaned records with no matching department (should return 0)
SELECT COUNT(*) AS orphaned
FROM transactions t
LEFT JOIN departments d ON t.department_id = d.department_id
WHERE d.department_id IS NULL;

-- Check 4: Row count reconciliation
SELECT
    (SELECT COUNT(*) FROM transactions)                       AS total_rows,
    (SELECT COUNT(*) FROM transactions WHERE status='Approved') AS approved,
    (SELECT COUNT(*) FROM transactions WHERE status='Pending')  AS pending,
    (SELECT COUNT(*) FROM transactions WHERE status='Rejected') AS rejected;