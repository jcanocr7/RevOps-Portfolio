import pandas as pd

# 1. Load the data from the main data folder
print("Loading data from 'data/' ...")
subs_df = pd.read_csv("data/subscriptions.csv")
usage_df = pd.read_csv("data/usage_events.csv")

# 2. Preview the data (like looking at the top 5 rows in Excel)
print("\nPreview of subscriptions:")
print(subs_df.head())

# 3. Aggregate usage (pivoting)
usage_counts = (
    usage_df.groupby("customer_id")["event_count"]
    .sum()
    .reset_index()
)
usage_counts.columns = ["customer_id", "total_usage"]

# 4. Merge subscriptions + usage (this is your Excel VLOOKUP)
df = pd.merge(subs_df, usage_counts, on="customer_id", how="left")

# Fill missing usage with 0
df["total_usage"] = df["total_usage"].fillna(0)

print("\n--- Data Stats ---")
print(df[["mrr", "total_usage"]].describe())

# 5. Define "High Risk" logic
# Rule: customers paying > 20 EUR MRR AND usage < 1000 events
risk_filter = (df["mrr"] > 20) & (df["total_usage"] < 1000)

# Apply the filter to create a clean copy
risky_customers = df[risk_filter].copy()

# 6. Sort by who pays us the most (prioritize the biggest fires)
risky_customers = risky_customers.sort_values(by="mrr", ascending=False)

# 7. Output the results
print("\nHIGH CHURN RISK ALERT")
print(f"Found {len(risky_customers)} customers paying > 20 EUR with usage < 1000.")
print(risky_customers[["customer_id", "plan_tier", "mrr", "total_usage"]].head(10))

# Optional: Export to CSV for the sales team
risky_customers.to_csv("high_risk_customers.csv", index=False)
print("\nExported results to 'high_risk_customers.csv'")