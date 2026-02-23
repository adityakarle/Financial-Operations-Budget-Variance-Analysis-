import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

DB_CONFIG = {
    'host':     'localhost',
    'database': 'budget_analysis',
    'user':     'postgres',
    'password': 'Admin',
    'port':     5432
}

print("Connecting to database...")
conn = psycopg2.connect(**DB_CONFIG)
cur  = conn.cursor()

print("Loading CSV files...")
budgets_df = pd.read_csv('../data/budgets.csv')
txn_df     = pd.read_csv('../data/transactions.csv')

print("Inserting departments...")
depts = pd.concat([budgets_df['department'], txn_df['department']]).unique()
execute_values(cur, 'INSERT INTO departments(department_name) VALUES %s ON CONFLICT DO NOTHING',
               [(d,) for d in depts])

print("Inserting categories...")
cats = pd.concat([budgets_df['category'], txn_df['category']]).unique()
execute_values(cur, 'INSERT INTO categories(category_name) VALUES %s ON CONFLICT DO NOTHING',
               [(c,) for c in cats])

cur.execute('SELECT department_name, department_id FROM departments')
dept_map = {r[0]: r[1] for r in cur.fetchall()}

cur.execute('SELECT category_name, category_id FROM categories')
cat_map  = {r[0]: r[1] for r in cur.fetchall()}

print("Inserting budgets...")
budget_rows = [
    (dept_map[r['department']], cat_map[r['category']], r['month'], r['budgeted_amount'])
    for _, r in budgets_df.iterrows()
]
execute_values(cur,
    'INSERT INTO budgets(department_id,category_id,month,budgeted_amount) VALUES %s',
    budget_rows, page_size=1000)
print("Budgets loaded!")

print("Inserting transactions (this takes 2-5 minutes)...")
txn_rows = [
    (r['transaction_id'], r['date'], dept_map[r['department']],
     cat_map[r['category']], r['vendor'], r['description'],
     r['amount'], r['approved_by'], r['status'])
    for _, r in txn_df.iterrows()
]
execute_values(cur,
    '''INSERT INTO transactions
       (transaction_id,date,department_id,category_id,vendor,
        description,amount,approved_by,status) VALUES %s''',
    txn_rows, page_size=2000)
print("Transactions loaded!")

conn.commit()
cur.close()
conn.close()
print("All done! Database is ready.")