# Methodology

## Data Model Overview

This analytics portfolio uses a normalized relational data model designed for SaaS revenue operations:

- **Customers**: Core entity representing each paying account with acquisition metadata (channel, signup date, company size)
- **Subscriptions**: Tracks the full subscription lifecycle including plan tier, MRR, and status transitions
- **Usage Events**: Product engagement signals aggregated by event type and date
- **Sales Touches**: Customer success and sales interaction history for engagement tracking

The schema supports both point-in-time analysis (current state queries) and time-series analysis (cohort trends, MRR movements).

## Why These 5 Queries Matter for RevOps

1. **Cohort Retention**: The foundation of SaaS unit economics. Retention curves reveal product-market fit strength and identify cohorts requiring intervention. This directly informs LTV calculations and board-level reporting.

2. **MRR Waterfall**: Decomposes revenue changes into actionable categories. New MRR validates acquisition effectiveness, expansion shows upsell success, contraction and churn highlight retention issues. Essential for monthly business reviews.

3. **Expansion Readiness**: Proactively identifies upsell opportunities by finding customers whose usage patterns exceed their plan tier. Prioritizes sales outreach based on engagement data rather than intuition.

4. **Churn Risk Segmentation**: Combines declining usage trends with sales engagement gaps to flag at-risk accounts. Enables proactive retention campaigns before customers reach the cancellation decision.

5. **Channel LTV Efficiency**: Evaluates acquisition channel ROI by comparing customer lifetime value across sources. Informs marketing budget allocation and identifies channels delivering high-value customers.

## Forecasting Approach

The revenue forecast model applies cohort-based retention decay to current MRR:

1. Calculate historical retention rates at each month since signup
2. Derive month-over-month retention from the cumulative curve
3. Apply this retention rate forward to project MRR decay
4. Generate scenario bands with +/-10% retention adjustments

This approach assumes historical retention patterns persist and doesn't account for seasonality or new customer acquisition. It provides a conservative baseline useful for capacity planning and churn target-setting.

## Limitations and Assumptions

- **No new customer acquisition**: Forecast models existing revenue decay only
- **Constant retention**: Assumes retention rates remain stable over the forecast period
- **No seasonality adjustment**: Model doesn't account for seasonal fluctuations
- **Aggregated retention**: Uses average across all cohorts rather than cohort-specific curves
- **Data recency**: Analysis quality depends on data completeness and freshness
