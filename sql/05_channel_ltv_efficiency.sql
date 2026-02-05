-- Channel LTV Efficiency Analysis
-- Question: Which acquisition channels deliver the highest customer lifetime value?
-- Business Value: Informs marketing budget allocation and CAC payback analysis

WITH customer_ltv AS (
    -- Calculate lifetime value for each customer (sum of all MRR payments)
    SELECT
        s.customer_id,
        SUM(
            s.mrr * (
                -- Number of months the subscription was active
                EXTRACT(YEAR FROM AGE(COALESCE(s.end_date, CURRENT_DATE), s.start_date)) * 12 +
                EXTRACT(MONTH FROM AGE(COALESCE(s.end_date, CURRENT_DATE), s.start_date)) + 1
            )
        ) AS lifetime_value,
        MIN(s.start_date) AS first_subscription_date,
        MAX(COALESCE(s.end_date, CURRENT_DATE)) AS last_active_date
    FROM subscriptions s
    GROUP BY s.customer_id
),

customer_lifetime_months AS (
    -- Calculate how many months each customer has been active
    SELECT
        customer_id,
        lifetime_value,
        EXTRACT(YEAR FROM AGE(last_active_date, first_subscription_date)) * 12 +
        EXTRACT(MONTH FROM AGE(last_active_date, first_subscription_date)) + 1 AS lifetime_months
    FROM customer_ltv
),

channel_metrics AS (
    -- Aggregate LTV metrics by acquisition channel
    SELECT
        c.acquisition_channel,
        COUNT(DISTINCT c.customer_id) AS customer_count,
        ROUND(AVG(clm.lifetime_months), 1) AS avg_lifetime_months,
        ROUND(AVG(clm.lifetime_value), 2) AS avg_ltv,
        ROUND(SUM(clm.lifetime_value), 2) AS total_ltv,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clm.lifetime_value), 2) AS median_ltv
    FROM customers c
    JOIN customer_lifetime_months clm ON c.customer_id = clm.customer_id
    GROUP BY c.acquisition_channel
)

SELECT
    acquisition_channel,
    customer_count,
    avg_lifetime_months,
    avg_ltv,
    median_ltv,
    total_ltv,
    RANK() OVER (ORDER BY avg_ltv DESC) AS ltv_rank
FROM channel_metrics
ORDER BY avg_ltv DESC;
