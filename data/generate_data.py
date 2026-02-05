"""
SaaS Revenue Data Generator - Black Box
Run once to generate CSVs. You don't need to understand this.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

np.random.seed(42)
random.seed(42)

START_DATE = datetime(2023, 7, 1)
END_DATE = datetime(2024, 12, 31)
NUM_CUSTOMERS = 500

PLAN_TIERS = {'Starter': {'price': 49, 'weight': 0.45}, 'Growth': {'price': 149, 'weight': 0.35}, 'Enterprise': {'price': 499, 'weight': 0.20}}
CHANNELS = {'Direct': 0.25, 'Paid Ads': 0.30, 'Referral': 0.20, 'Partner': 0.15, 'Events': 0.10}
COUNTRIES = {'Germany': 0.35, 'UK': 0.20, 'France': 0.15, 'Netherlands': 0.10, 'Spain': 0.08, 'Italy': 0.07, 'Other EU': 0.05}
CHURN_RATES = {'Starter': 0.08, 'Growth': 0.04, 'Enterprise': 0.02}
INDUSTRIES = ['SaaS', 'E-commerce', 'Finance', 'Healthcare', 'Manufacturing', 'Consulting', 'Media', 'Education']

def random_date(start, end):
    delta = end - start
    return start + timedelta(days=random.randint(0, delta.days))

def weighted_choice(choices_dict):
    items = list(choices_dict.keys())
    # Handle both simple dicts {key: weight} and nested {key: {weight: x}}
    first_val = list(choices_dict.values())[0]
    if isinstance(first_val, dict):
        weights = [v['weight'] for v in choices_dict.values()]
    else:
        weights = list(choices_dict.values())
    return random.choices(items, weights=weights, k=1)[0]

# Generate Customers
customers = []
for i in range(1, NUM_CUSTOMERS + 1):
    signup = random_date(START_DATE, END_DATE - timedelta(days=60))
    customers.append({
        'customer_id': f'CUST_{i:04d}',
        'company_name': f'Company_{i}',
        'industry': random.choice(INDUSTRIES),
        'country': weighted_choice(COUNTRIES),
        'acquisition_channel': weighted_choice(CHANNELS),
        'signup_date': signup.strftime('%Y-%m-%d'),
        'employee_count': random.choice([10, 25, 50, 100, 250, 500, 1000])
    })

customers_df = pd.DataFrame(customers)

# Generate Subscriptions
subscriptions = []
sub_id = 1
for _, cust in customers_df.iterrows():
    signup = datetime.strptime(cust['signup_date'], '%Y-%m-%d')
    current_plan = weighted_choice(PLAN_TIERS)
    current_start = signup
    
    while current_start < END_DATE:
        churn_prob = CHURN_RATES[current_plan]
        months_active = random.randint(2, 18)
        end_date = min(current_start + timedelta(days=30 * months_active), END_DATE)
        
        churned = random.random() < (churn_prob * months_active * 0.5)
        if churned and end_date < END_DATE:
            status = 'churned'
            actual_end = end_date
        elif end_date >= END_DATE:
            status = 'active'
            actual_end = None
        else:
            status = 'upgraded' if current_plan != 'Enterprise' else 'active'
            actual_end = end_date
        
        subscriptions.append({
            'subscription_id': f'SUB_{sub_id:05d}',
            'customer_id': cust['customer_id'],
            'plan_tier': current_plan,
            'mrr': PLAN_TIERS[current_plan]['price'],
            'start_date': current_start.strftime('%Y-%m-%d'),
            'end_date': actual_end.strftime('%Y-%m-%d') if actual_end else None,
            'status': status
        })
        sub_id += 1
        
        if status == 'churned' or status == 'active':
            break
        
        current_start = actual_end + timedelta(days=1)
        if current_plan == 'Starter':
            current_plan = 'Growth' if random.random() < 0.7 else 'Enterprise'
        elif current_plan == 'Growth':
            current_plan = 'Enterprise'

subscriptions_df = pd.DataFrame(subscriptions)

# Generate Usage Events
EVENT_TYPES = ['login', 'feature_use', 'export', 'api_call', 'invite_user', 'dashboard_view', 'report_run']
usage_events = []
event_id = 1

for _, sub in subscriptions_df.iterrows():
    start = datetime.strptime(sub['start_date'], '%Y-%m-%d')
    end = datetime.strptime(sub['end_date'], '%Y-%m-%d') if sub['end_date'] else END_DATE
    
    base_intensity = {'Starter': 15, 'Growth': 30, 'Enterprise': 60}[sub['plan_tier']]
    
    current = start
    while current <= end:
        monthly_events = int(np.random.poisson(base_intensity))
        for _ in range(monthly_events):
            event_date = current + timedelta(days=random.randint(0, 29))
            if event_date <= end:
                usage_events.append({
                    'event_id': f'EVT_{event_id:07d}',
                    'customer_id': sub['customer_id'],
                    'event_type': random.choice(EVENT_TYPES),
                    'event_date': event_date.strftime('%Y-%m-%d'),
                    'event_count': random.randint(1, 10)
                })
                event_id += 1
        current += timedelta(days=30)

usage_df = pd.DataFrame(usage_events)

# Generate Sales Touches
TOUCH_TYPES = ['email', 'call', 'meeting', 'demo', 'qbr', 'support_ticket', 'webinar']
TOUCH_OUTCOMES = ['positive', 'neutral', 'no_response', 'negative']
sales_touches = []
touch_id = 1

for _, cust in customers_df.iterrows():
    signup = datetime.strptime(cust['signup_date'], '%Y-%m-%d')
    num_touches = np.random.poisson(4) + 1
    
    for _ in range(num_touches):
        touch_date = random_date(signup, END_DATE)
        sales_touches.append({
            'touch_id': f'TCH_{touch_id:06d}',
            'customer_id': cust['customer_id'],
            'touch_type': random.choice(TOUCH_TYPES),
            'touch_date': touch_date.strftime('%Y-%m-%d'),
            'outcome': random.choices(TOUCH_OUTCOMES, weights=[0.3, 0.4, 0.25, 0.05])[0],
            'sales_rep': f'Rep_{random.randint(1, 15):02d}'
        })
        touch_id += 1

touches_df = pd.DataFrame(sales_touches)

# Save CSVs
customers_df.to_csv('customers.csv', index=False)
subscriptions_df.to_csv('subscriptions.csv', index=False)
usage_df.to_csv('usage_events.csv', index=False)
touches_df.to_csv('sales_touches.csv', index=False)

print(f"✅ Generated:")
print(f"   - {len(customers_df)} customers")
print(f"   - {len(subscriptions_df)} subscriptions")
print(f"   - {len(usage_df)} usage events")
print(f"   - {len(touches_df)} sales touches")
