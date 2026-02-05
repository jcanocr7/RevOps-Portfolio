-- MRR Movement Waterfall Analysis
-- Question: How did MRR change month-over-month? (New, Expansion, Contraction, Churn)
-- Business Value: Decomposes revenue changes to identify growth drivers and areas of concern

WITH monthly_mrr AS (
    -- Calculate each customer's MRR for each month they were active
    SELECT
        s.customer_id,
        DATE_TRUNC('month', d.month_date)::date AS month,
        SUM(s.mrr) AS mrr
    FROM subscriptions s
    CROSS JOIN LATERAL generate_series(
        DATE_TRUNC('month', s.start_date),
        DATE_TRUNC('month', COALESCE(s.end_date, CURRENT_DATE)),
        INTERVAL '1 month'
    ) AS d(month_date)
    GROUP BY s.customer_id, DATE_TRUNC('month', d.month_date)
),

mrr_changes AS (
    -- Compare each customer's MRR to the previous month using LAG
    SELECT
        customer_id,
        month,
        mrr AS current_mrr,
        LAG(mrr) OVER (PARTITION BY customer_id ORDER BY month) AS previous_mrr,
        LAG(month) OVER (PARTITION BY customer_id ORDER BY month) AS previous_month
    FROM monthly_mrr
),

mrr_movements AS (
    -- Categorize each MRR change into movement types
    SELECT
        month,
        customer_id,
        current_mrr,
        previous_mrr,
        CASE
            -- New: First month for this customer (no previous MRR)
            WHEN previous_mrr IS NULL THEN 'new'
            -- Churned: Had MRR last month but gap in months (not consecutive)
            WHEN previous_month < month - INTERVAL '1 month' THEN 'new'
            -- Expansion: Current MRR higher than previous month
            WHEN current_mrr > previous_mrr THEN 'expansion'
            -- Contraction: Current MRR lower than previous month
            WHEN current_mrr < previous_mrr THEN 'contraction'
            -- Retained: Same MRR as previous month
            ELSE 'retained'
        END AS movement_type,
        CASE
            WHEN previous_mrr IS NULL THEN current_mrr
            WHEN previous_month < month - INTERVAL '1 month' THEN current_mrr
            WHEN current_mrr > previous_mrr THEN current_mrr - previous_mrr
            WHEN current_mrr < previous_mrr THEN current_mrr - previous_mrr
            ELSE 0
        END AS mrr_change
    FROM mrr_changes
),

churned_mrr AS (
    -- Identify churned MRR (customers who had MRR but don't appear next month)
    SELECT
        mc.month + INTERVAL '1 month' AS month,
        mc.customer_id,
        -mc.current_mrr AS mrr_change,
        'churned' AS movement_type
    FROM mrr_changes mc
    LEFT JOIN monthly_mrr mm ON mc.customer_id = mm.customer_id
        AND mm.month = mc.month + INTERVAL '1 month'
    WHERE mm.customer_id IS NULL
      AND mc.month < DATE_TRUNC('month', CURRENT_DATE)
)

SELECT
    TO_CHAR(month, 'YYYY-MM') AS month,
    SUM(CASE WHEN movement_type = 'new' THEN mrr_change ELSE 0 END) AS new_mrr,
    SUM(CASE WHEN movement_type = 'expansion' THEN mrr_change ELSE 0 END) AS expansion_mrr,
    SUM(CASE WHEN movement_type = 'contraction' THEN mrr_change ELSE 0 END) AS contraction_mrr,
    SUM(CASE WHEN movement_type = 'churned' THEN mrr_change ELSE 0 END) AS churned_mrr,
    SUM(mrr_change) AS net_new_mrr,
    SUM(SUM(mrr_change)) OVER (ORDER BY month) AS cumulative_mrr
FROM (
    SELECT month, customer_id, mrr_change, movement_type
    FROM mrr_movements
    WHERE movement_type != 'retained'
    UNION ALL
    SELECT month, customer_id, mrr_change, movement_type
    FROM churned_mrr
) combined
GROUP BY month
ORDER BY month;
