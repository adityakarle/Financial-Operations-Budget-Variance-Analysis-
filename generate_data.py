import pandas as pd
import random
from faker import Faker
from datetime import datetime, timedelta
import os

fake = Faker()
random.seed(42)

DEPARTMENTS = ['Engineering', 'Marketing', 'Sales', 'HR', 'Finance', 'Operations', 'IT', 'Legal']
CATEGORIES  = ['Salaries', 'Software', 'Travel', 'Marketing Spend', 'Office Supplies',
                'Consulting', 'Infrastructure', 'Training', 'Utilities', 'Miscellaneous']
START_DATE  = datetime(2023, 1, 1)
END_DATE    = datetime(2024, 12, 31)
NUM_TRANSACTIONS = 180000

budget_rows = []
for dept in DEPARTMENTS:
    for month in pd.date_range(START_DATE, END_DATE, freq='MS'):
        for cat in CATEGORIES:
            budget_rows.append({
                'department': dept,
                'category': cat,
                'month': month.strftime('%Y-%m-01'),
                'budgeted_amount': round(random.uniform(550000, 750000), 2)
            })
budgets_df = pd.DataFrame(budget_rows)

transactions = []
for i in range(NUM_TRANSACTIONS):
    dept = random.choice(DEPARTMENTS)
    cat  = random.choice(CATEGORIES)
    date = START_DATE + timedelta(days=random.randint(0, 730))
    variance_factor = random.gauss(1.0, 0.15)
    transactions.append({
        'transaction_id': f'TXN{i+1:07d}',
        'date': date.strftime('%Y-%m-%d'),
        'department': dept,
        'category': cat,
        'vendor': fake.company(),
        'description': fake.bs(),
        'amount': round(abs(random.uniform(100, 15000) * variance_factor), 2),
        'approved_by': fake.name(),
        'status': random.choices(['Approved','Pending','Rejected'], weights=[85,10,5])[0]
    })
transactions_df = pd.DataFrame(transactions)

os.makedirs('../data', exist_ok=True)
budgets_df.to_csv('../data/budgets.csv', index=False)
transactions_df.to_csv('../data/transactions.csv', index=False)
print(f'Generated {len(transactions_df):,} transactions')
print(f'Generated {len(budgets_df):,} budget records')
print('Files saved to data/ folder')
