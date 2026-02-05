"""
Simple Revenue Forecast
-----------------------
Goal: Show a basic, beginner-friendly way to:
- Calculate historical Monthly Recurring Revenue (MRR) by month
- Build a straight-line forecast for the next 6 months

How to run (from the `python` folder):
> python revenue_forecast.py
"""

import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime
from pathlib import Path

# Paths (kept very simple)
SCRIPT_DIR = Path(__file__).parent
DATA_PATH = SCRIPT_DIR.parent / "data" / "subscriptions.csv"
OUTPUT_DIR = SCRIPT_DIR / "output"
OUTPUT_DIR.mkdir(exist_ok=True)


def load_subscriptions():
    """Load subscriptions data from the data folder."""
    print(f"Loading subscriptions from: {DATA_PATH}")
    subs = pd.read_csv(
        DATA_PATH,
        parse_dates=["start_date", "end_date"],
    )
    return subs


def build_monthly_mrr(subscriptions: pd.DataFrame) -> pd.DataFrame:
    """
    Build a simple monthly MRR time series.

    For each subscription, we:
    - Generate one row per active month between start_date and end_date
    - Add its MRR to that month
    """
    rows = []

    for _, row in subscriptions.iterrows():
        start = row["start_date"]
        # If no end date, treat as active until "today"
        end = row["end_date"] if pd.notna(row["end_date"]) else datetime.today()

        # We only care about year-month (e.g. 2024-01)
        current = start.replace(day=1)
        last_month = end.replace(day=1)

        while current <= last_month:
            rows.append({"month": current, "mrr": row["mrr"]})
            # move to next month
            if current.month == 12:
                current = current.replace(year=current.year + 1, month=1)
            else:
                current = current.replace(month=current.month + 1)

    monthly = pd.DataFrame(rows)
    monthly_mrr = monthly.groupby("month")["mrr"].sum().reset_index()
    monthly_mrr = monthly_mrr.sort_values("month")
    return monthly_mrr


def build_straight_line_forecast(history: pd.DataFrame, months_ahead: int = 6) -> pd.DataFrame:
    """
    Build a very simple straight-line forecast:
    - Look at the last 6 historical months
    - Compute the average monthly change in MRR
    - Project the next 6 months using that average change
    """
    hist = history.copy()
    hist["mrr_change"] = hist["mrr"].diff()

    last_six = hist.tail(6)
    avg_change = last_six["mrr_change"].mean()

    print(f"\nAverage monthly MRR change over last 6 months: {avg_change:,.2f}")

    last_month = hist["month"].max()
    last_mrr = hist["mrr"].iloc[-1]

    forecast_rows = []
    current_month = last_month
    current_mrr = last_mrr

    for _ in range(months_ahead):
        # move to next month
        if current_month.month == 12:
            current_month = current_month.replace(year=current_month.year + 1, month=1)
        else:
            current_month = current_month.replace(month=current_month.month + 1)

        current_mrr = current_mrr + avg_change
        forecast_rows.append({"month": current_month, "mrr": max(current_mrr, 0)})

    forecast_df = pd.DataFrame(forecast_rows)
    return forecast_df


def plot_history_and_forecast(history: pd.DataFrame, forecast: pd.DataFrame):
    """Create a simple line chart for historical vs forecast MRR."""
    plt.figure(figsize=(10, 5))

    # Historical
    plt.plot(history["month"], history["mrr"], label="Historical MRR", marker="o")

    # Forecast
    plt.plot(
        forecast["month"],
        forecast["mrr"],
        label="Forecast (straight line)",
        marker="o",
        linestyle="--",
        color="orange",
    )

    plt.title("Monthly MRR and 6-Month Straight-Line Forecast")
    plt.xlabel("Month")
    plt.ylabel("MRR (EUR)")
    plt.legend()
    plt.xticks(rotation=45)
    plt.tight_layout()

    output_path = OUTPUT_DIR / "mrr_trend_and_forecast.png"
    plt.savefig(output_path, dpi=150)
    plt.close()

    print(f"\nSaved chart to: {output_path}")


def print_summary(history: pd.DataFrame, forecast: pd.DataFrame):
    """Print a simple text summary to the console."""
    current_mrr = history["mrr"].iloc[-1]
    future_mrr = forecast["mrr"].iloc[-1]
    growth_pct = (future_mrr - current_mrr) / current_mrr * 100

    print("\n==============================")
    print("REVENUE FORECAST SUMMARY")
    print("==============================")
    print(f"Current MRR:         €{current_mrr:,.0f}")
    print(f"MRR in 6 months:     €{future_mrr:,.0f}")
    print(f"Expected growth:     {growth_pct:+.1f}% over 6 months")
    print("==============================\n")


def main():
    # 1) Load data
    subs = load_subscriptions()

    # 2) Build historical monthly MRR
    monthly_mrr = build_monthly_mrr(subs)
    print("\nLast 6 months of historical MRR:")
    print(monthly_mrr.tail(6))

    # 3) Build forecast
    forecast = build_straight_line_forecast(monthly_mrr, months_ahead=6)
    print("\n6-month forecast:")
    print(forecast)

    # 4) Plot everything
    plot_history_and_forecast(monthly_mrr, forecast)

    # 5) Text summary for the portfolio
    print_summary(monthly_mrr, forecast)


if __name__ == "__main__":
    main()
