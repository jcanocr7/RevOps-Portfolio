-- Churn Risk Segmentation
-- Question: Who is at risk based on declining usage + lack of sales engagement?
-- Business Value: Enables proactive retention outreach before customers churn

WITH current_subscriptions AS (
    -- Get active subscriptions only
    SELECT DISTINCT ON (customer_id)
        customer_id,
        plan_tier,
        mrr
    FROM subscriptions
    WHERE status = 'active'
    ORDER BY customer_id, start_date DESC
),

usage_30_days AS (
    -- Calculate average daily usage over the last 30 days
    SELECT
        customer_id,
        COALESCE(AVG(event_count), 0) AS avg_daily_events_30d
    FROM usage_events
    WHERE event_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY customer_id
),

usage_90_days AS (
    -- Calculate average daily usage over the last 90 days
    SELECT
        customer_id,
        COALESCE(AVG(event_count), 0) AS avg_daily_events_90d
    FROM usage_events
    WHERE event_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY customer_id
),

last_touch AS (
    -- Find the most recent sales touch for each customer
    SELECT
        customer_id,
        MAX(touch_date) AS last_touch_date
    FROM sales_touches
    GROUP BY customer_id
),

churn_risk_data AS (
    -- Combine metrics to calculate risk factors
    SELECT
        cs.customer_id,
        cs.plan_tier,
        cs.mrr,
        COALESCE(u30.avg_daily_events_30d, 0) AS avg_events_30d,
        COALESCE(u90.avg_daily_events_90d, 0) AS avg_events_90d,
        CASE
            WHEN u90.avg_daily_events_90d > 0
            THEN ROUND((u30.avg_daily_events_30d / u90.avg_daily_events_90d) * 100, 1)
            ELSE 0
        END AS usage_trend_pct,
        COALESCE(CURRENT_DATE - lt.last_touch_date, 999) AS days_since_touch
    FROM current_subscriptions cs
    LEFT JOIN usage_30_days u30 ON cs.customer_id = u30.customer_id
    LEFT JOIN usage_90_days u90 ON cs.customer_id = u90.customer_id
    LEFT JOIN last_touch lt ON cs.customer_id = lt.customer_id
)

SELECT
    customer_id,
    plan_tier,
    mrr,
    usage_trend_pct,
    days_since_touch,
    CASE
        -- High Risk: Usage dropped significantly AND no recent engagement
        WHEN usage_trend_pct < 50 AND days_since_touch > 60 THEN 'High'
        -- Medium Risk: Either usage dropped OR no recent engagement
        WHEN usage_trend_pct < 50 OR days_since_touch > 60 THEN 'Medium'
        -- Low Risk: Healthy usage and recent engagement
        ELSE 'Low'
    END AS risk_tier
FROM churn_risk_data
WHERE usage_trend_pct < 50 OR days_since_touch > 60
ORDER BY
    CASE
        WHEN usage_trend_pct < 50 AND days_since_touch > 60 THEN 1
        WHEN usage_trend_pct < 50 OR days_since_touch > 60 THEN 2
        ELSE 3
    END,
    mrr DESC;
