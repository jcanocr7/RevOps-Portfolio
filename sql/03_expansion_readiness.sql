-- Expansion Readiness Scoring
-- Question: Which customers on Starter/Growth plans have high usage but haven't upgraded?
-- Business Value: Identifies upsell opportunities where product engagement exceeds plan tier

WITH current_subscriptions AS (
    -- Get each customer's current active subscription
    SELECT DISTINCT ON (customer_id)
        customer_id,
        plan_tier,
        mrr,
        start_date
    FROM subscriptions
    WHERE status = 'active'
    ORDER BY customer_id, start_date DESC
),

usage_last_90_days AS (
    -- Calculate total usage in the last 90 days for each customer
    SELECT
        customer_id,
        SUM(event_count) AS total_events
    FROM usage_events
    WHERE event_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY customer_id
),

usage_percentiles AS (
    -- Calculate usage percentile for each customer
    SELECT
        customer_id,
        total_events,
        PERCENT_RANK() OVER (ORDER BY total_events) AS usage_percentile
    FROM usage_last_90_days
),

last_upgrade AS (
    -- Find the most recent upgrade date for each customer
    SELECT
        customer_id,
        MAX(start_date) AS last_upgrade_date
    FROM subscriptions
    WHERE status IN ('active', 'upgraded')
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

expansion_candidates AS (
    -- Combine all metrics to identify expansion-ready customers
    SELECT
        cs.customer_id,
        cs.plan_tier AS current_plan,
        cs.mrr,
        ROUND(up.usage_percentile * 100, 1) AS usage_percentile,
        COALESCE(CURRENT_DATE - lt.last_touch_date, 999) AS days_since_last_touch,
        CASE cs.plan_tier
            WHEN 'Starter' THEN (149 - cs.mrr) * 12  -- Upgrade to Growth
            WHEN 'Growth' THEN (499 - cs.mrr) * 12   -- Upgrade to Enterprise
            ELSE 0
        END AS expansion_arr_potential
    FROM current_subscriptions cs
    JOIN usage_percentiles up ON cs.customer_id = up.customer_id
    LEFT JOIN last_upgrade lu ON cs.customer_id = lu.customer_id
    LEFT JOIN last_touch lt ON cs.customer_id = lt.customer_id
    WHERE cs.plan_tier IN ('Starter', 'Growth')
      AND up.usage_percentile >= 0.75  -- Top 25% usage
      AND (lu.last_upgrade_date IS NULL
           OR lu.last_upgrade_date < CURRENT_DATE - INTERVAL '6 months')
)

SELECT
    customer_id,
    current_plan,
    mrr,
    usage_percentile,
    days_since_last_touch,
    expansion_arr_potential
FROM expansion_candidates
ORDER BY expansion_arr_potential DESC, usage_percentile DESC;
