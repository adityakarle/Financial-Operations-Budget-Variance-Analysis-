-- =====================================================
-- Database Schema & Table Creation
-- =====================================================

CREATE TABLE departments (
    department_id   SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE categories (
    category_id   SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE budgets (
    budget_id        SERIAL PRIMARY KEY,
    department_id    INT REFERENCES departments(department_id),
    category_id      INT REFERENCES categories(category_id),
    month            DATE NOT NULL,
    budgeted_amount  NUMERIC(12, 2) NOT NULL
);

CREATE TABLE transactions (
    transaction_id  VARCHAR(20) PRIMARY KEY,
    date            DATE NOT NULL,
    department_id   INT REFERENCES departments(department_id),
    category_id     INT REFERENCES categories(category_id),
    vendor          VARCHAR(200),
    description     TEXT,
    amount          NUMERIC(12, 2) NOT NULL,
    approved_by     VARCHAR(100),
    status          VARCHAR(20) DEFAULT 'Pending'
);

-- Indexes for faster query performance
CREATE INDEX idx_transactions_date   ON transactions(date);
CREATE INDEX idx_transactions_dept   ON transactions(department_id);
CREATE INDEX idx_transactions_status ON transactions(status);