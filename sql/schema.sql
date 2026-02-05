-- Revenue Operations Analytics Schema
-- PostgreSQL/Supabase compatible table definitions

-- Customers table: Core customer information
CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    industry VARCHAR(100),
    country VARCHAR(100),
    acquisition_channel VARCHAR(50),
    signup_date DATE NOT NULL,
    employee_count INTEGER
);

-- Index for filtering by acquisition channel (used in LTV analysis)
CREATE INDEX idx_customers_channel ON customers(acquisition_channel);

-- Index for cohort analysis by signup date
CREATE INDEX idx_customers_signup ON customers(signup_date);


-- Subscriptions table: Subscription lifecycle and MRR
CREATE TABLE subscriptions (
    subscription_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL REFERENCES customers(customer_id),
    plan_tier VARCHAR(50) NOT NULL,
    mrr DECIMAL(10, 2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) NOT NULL
);

-- Index for MRR waterfall queries (time-series analysis)
CREATE INDEX idx_subscriptions_dates ON subscriptions(start_date, end_date);

-- Index for customer subscription lookups
CREATE INDEX idx_subscriptions_customer ON subscriptions(customer_id);

-- Index for plan tier filtering (expansion analysis)
CREATE INDEX idx_subscriptions_tier ON subscriptions(plan_tier);


-- Usage events table: Product engagement tracking
CREATE TABLE usage_events (
    event_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL REFERENCES customers(customer_id),
    event_type VARCHAR(50) NOT NULL,
    event_date DATE NOT NULL,
    event_count INTEGER NOT NULL DEFAULT 1
);

-- Index for usage trend calculations (30-day vs 90-day comparisons)
CREATE INDEX idx_usage_customer_date ON usage_events(customer_id, event_date);

-- Index for event type analysis
CREATE INDEX idx_usage_event_type ON usage_events(event_type);


-- Sales touches table: Customer engagement history
CREATE TABLE sales_touches (
    touch_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL REFERENCES customers(customer_id),
    touch_type VARCHAR(50) NOT NULL,
    touch_date DATE NOT NULL,
    outcome VARCHAR(50),
    sales_rep VARCHAR(50)
);

-- Index for recency-based queries (days since last touch)
CREATE INDEX idx_touches_customer_date ON sales_touches(customer_id, touch_date);

-- Index for sales rep performance analysis
CREATE INDEX idx_touches_rep ON sales_touches(sales_rep);
