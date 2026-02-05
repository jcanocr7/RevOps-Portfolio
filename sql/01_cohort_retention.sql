-- Cohort Retention Analysis
-- Question: What are our month-over-month retention rates by signup cohort through Month 12?
-- Business Value: Identifies which cohorts retain best, enabling targeted interventions for underperforming groups

WITH cohort_base AS (
    -- Assign each customer to their signup month cohort
    SELECT
        customer_id,
        DATE_TRUNC('month', signup_date) AS cohort_month
    FROM customers
),

cohort_sizes AS (
    -- Calculate the starting size of each cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM cohort_base
    GROUP BY cohort_month
),

customer_active_months AS (
    -- Generate all months where each customer had an active subscription
    SELECT DISTINCT
        s.customer_id,
        generate_series(
            DATE_TRUNC('month', s.start_date),
            DATE_TRUNC('month', COALESCE(s.end_date, CURRENT_DATE)),
            INTERVAL '1 month'
        )::date AS active_month
    FROM subscriptions s
),

retention_data AS (
    -- Calculate retained customers at each month number for each cohort
    SELECT
        cb.cohort_month,
        EXTRACT(YEAR FROM AGE(cam.active_month, cb.cohort_month::date)) * 12 +
        EXTRACT(MONTH FROM AGE(cam.active_month, cb.cohort_month::date)) AS month_number,
        COUNT(DISTINCT cb.customer_id) AS retained_customers
    FROM cohort_base cb
    JOIN customer_active_months cam ON cb.customer_id = cam.customer_id
    WHERE cam.active_month >= cb.cohort_month
    GROUP BY cb.cohort_month, month_number
)

SELECT
    TO_CHAR(rd.cohort_month, 'YYYY-MM') AS cohort,
    cs.cohort_size,
    rd.month_number,
    rd.retained_customers,
    ROUND(rd.retained_customers * 100.0 / cs.cohort_size, 1) AS retention_pct
FROM retention_data rd
JOIN cohort_sizes cs ON rd.cohort_month = cs.cohort_month
WHERE rd.month_number BETWEEN 0 AND 12
ORDER BY rd.cohort_month, rd.month_number;
