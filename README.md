# SaaS Revenue Intelligence System

**A comprehensive Revenue Operations analytics portfolio demonstrating SQL, Python, and Power BI capabilities for GTM decision-making.**

---

## Overview

This project analyzes 18 months of synthetic SaaS company data (~500 customers, 3K subscriptions, 50K usage events, 8K sales touches) to answer critical revenue operations questions:

- How healthy is our customer retention?
- Where is MRR growth coming from (new, expansion, churn)?
- Which customers are ready for expansion but haven't been engaged?
- Who is at risk of churning based on behavior signals?
- Which acquisition channels deliver the best LTV?

Built to demonstrate end-to-end revenue analytics capabilities required for Revenue Operations, GTM Analytics, and Commercial Strategy roles in Berlin's tech/fintech ecosystem.

---

## Technical Stack

- **SQL:** PostgreSQL-compatible queries (window functions, CTEs, self-joins)
- **Python:** pandas, matplotlib, seaborn, statsmodels
- **Power BI:** 3-page interactive dashboard with drill-through functionality
- **Data Generation:** Python script creating realistic synthetic SaaS metrics

---

## Business Questions & Solutions

### 1. Cohort Retention Analysis (`sql/01_cohort_retention.sql`)

**Question:** What are our month-over-month retention rates by signup cohort through Month 12?

**Method:** Window functions to calculate cumulative retention, grouped by monthly cohort

**Insight:** Cohorts from Q1 2024 show 15% better M6 retention than Q3 2023 cohorts, suggesting product/onboarding improvements

### 2. MRR Movement Waterfall (`sql/02_mrr_waterfall.sql`)

**Question:** How did MRR change month-over-month? (New, Expansion, Contraction, Churn)

**Method:** Self-joins on subscriptions table with complex date logic to categorize MRR movements

**Insight:** October 2024 saw €45K new MRR offset by €28K churn, net growth €17K driven by expansion (€12K)

### 3. Expansion Readiness Scoring (`sql/03_expansion_readiness.sql`)

**Question:** Which customers on Starter/Growth plans have high usage but haven't upgraded?

**Method:** Join subscriptions + usage events + sales touches, filter for top 25% engagement with no upgrade in 6+ months

**Insight:** 47 customers identified as expansion-ready, representing €94K potential ARR if converted to next tier

### 4. Churn Risk Segmentation (`sql/04_churn_risk_segmentation.sql`)

**Question:** Who is at risk based on declining usage + lack of sales engagement?

**Method:** CTEs comparing 30-day vs 90-day usage trends, flagging customers with no touch in 60+ days

**Insight:** 23 customers flagged as high-risk (€156K ARR at stake), requiring immediate sales intervention

### 5. Channel Efficiency by LTV (`sql/05_channel_ltv_efficiency.sql`)

**Question:** Which acquisition channels deliver the highest customer lifetime value?

**Method:** Group by channel, calculate average LTV (sum of all MRR before churn), rank performance

**Insight:** Direct sales channel has 2.1× higher LTV than paid ads, but 5× longer sales cycle

---

## Python Forecasting Model

**File:** `python/revenue_forecast.ipynb`

**Objective:** Project MRR for next 6 months based on historical cohort retention curves and assumed new customer acquisition

**Methodology:**

1. Calculate historical monthly retention rates by cohort age
2. Apply retention curve to existing customer base
3. Model new customer acquisition (input parameter: 20/30/40 new customers per month)
4. Generate 3 scenarios: pessimistic (low retention + low acquisition), base, optimistic

**Output:**

- Base case: MRR grows from €287K (Jan 2025) to €342K (Jun 2025) — 19% growth
- Sensitivity: ±€25K variance between pessimistic/optimistic scenarios
- Visualization: Retention curves by cohort age, MRR forecast with confidence bands

**Key Learning:** Simple cohort-based forecasting often outperforms complex ML models for early-stage SaaS due to limited data and interpretability requirements

---

## Power BI Dashboard

**File:** `powerbi/revenue_health_dashboard.pbix`

### Page 1: Revenue Overview

- Current MRR: €287K (+12% QoQ)
- MRR Waterfall: New €92K | Expansion €34K | Contraction -€18K | Churn -€51K
- ARR by Segment: Enterprise 45% | Growth 32% | Starter 23%
- Monthly Churn Rate: 4.2% (trending down from 5.8% in Q3)

### Page 2: Customer Health

- 47 Expansion-Ready Customers (€94K opportunity)
- 23 High-Risk Customers (€156K ARR at risk)
- Usage Intensity: 68% customers in "Engaged" tier (10+ events/week)
- Sales Coverage Gap: 34% of customers had no touch in 90+ days

### Page 3: GTM Efficiency

- CAC by Channel: Direct €2.4K | Referral €890 | Paid Ads €3.1K
- LTV:CAC Ratio: Direct 5.2× | Referral 8.1× | Paid Ads 2.8×
- Time-to-First-Paid: Avg 14 days (Direct 9 days, Paid Ads 21 days)
- Sales Cycle by Tier: Starter 12 days | Growth 28 days | Enterprise 67 days

**Interactivity:** Slicers for date range, plan tier, channel, country. Drill-through from segment lists to individual customer detail.

---

## What This Project Demonstrates

✅ **SQL Proficiency:** Window functions, CTEs, self-joins, complex date logic, multi-table joins

✅ **Python Analytics:** pandas data manipulation, time-series forecasting, statistical modeling

✅ **Data Visualization:** Executive-level dashboards with KPI selection aligned to SaaS unit economics

✅ **Business Acumen:** Understands MRR movements, cohort analysis, LTV:CAC, expansion vs churn dynamics

✅ **RevOps Thinking:** Builds systems that answer "What should Sales do tomorrow?" not just "What happened last month?"

## Author

**Jorge Cano**

Revenue Operations Professional | Berlin, Germany

[LinkedIn](https://linkedin.com/in/jorge-cano-reyes) | [Email](mailto:canojorge12r@gmail.com)

*Built as portfolio project to demonstrate technical capabilities for Revenue Operations, GTM Analytics, and Commercial Strategy roles. Data is synthetically generated; all business insights are illustrative.*
