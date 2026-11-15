USE digital_payment_fraud_dw;


-- 1. Overall Fraud Analysis
SELECT
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS fraud_percentage
FROM fact_transaction;


-- 2. Fraud by Merchant Category
SELECT
    m.merchant_category,
    COUNT(*) AS total_transactions,
    SUM(t.is_fraud) AS fraud_transactions,
    ROUND(SUM(t.is_fraud) * 100.0 / COUNT(*), 2) AS fraud_percentage
FROM fact_transaction t
JOIN dim_merchant m
    ON t.merchant_key = m.merchant_key
GROUP BY m.merchant_category
ORDER BY fraud_percentage DESC;


-- 3. Fraud by Time Period
SELECT
    d.time_period,
    COUNT(*) AS total_transactions,
    SUM(t.is_fraud) AS fraud_transactions,
    ROUND(SUM(t.is_fraud) * 100.0 / COUNT(*), 2) AS fraud_percentage
FROM fact_transaction t
JOIN dim_time d
    ON t.time_key = d.time_key
GROUP BY d.time_period
ORDER BY fraud_percentage DESC;


-- 4. Fraud by Risk Level
SELECT
    r.risk_level,
    COUNT(*) AS total_transactions,
    SUM(t.is_fraud) AS fraud_transactions,
    ROUND(SUM(t.is_fraud) * 100.0 / COUNT(*), 2) AS fraud_percentage
FROM fact_transaction t
JOIN dim_risk r
    ON t.risk_key = r.risk_key
GROUP BY r.risk_level
ORDER BY fraud_percentage DESC;


-- 5. Fraud by Foreign Transaction
SELECT
    foreign_transaction,
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS fraud_percentage
FROM fact_transaction
GROUP BY foreign_transaction
ORDER BY fraud_percentage DESC;


-- 6. Fraud by Location Mismatch
SELECT
    location_mismatch,
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS fraud_percentage
FROM fact_transaction
GROUP BY location_mismatch
ORDER BY fraud_percentage DESC;


-- 7. Average Device Trust Score by Fraud Status
SELECT
    is_fraud,
    COUNT(*) AS total_transactions,
    ROUND(AVG(device_trust_score), 2) AS average_device_trust_score
FROM fact_transaction
GROUP BY is_fraud
ORDER BY is_fraud;


-- 8. Average Transaction Velocity by Fraud Status
SELECT
    is_fraud,
    COUNT(*) AS total_transactions,
    ROUND(AVG(velocity_last_24h), 2) AS average_velocity
FROM fact_transaction
GROUP BY is_fraud
ORDER BY is_fraud;


-- 9. Average and Maximum Transaction Amount
SELECT
    is_fraud,
    COUNT(*) AS total_transactions,
    ROUND(AVG(amount), 2) AS average_amount,
    MAX(amount) AS maximum_amount
FROM fact_transaction
GROUP BY is_fraud
ORDER BY is_fraud;


-- 10. Fraud by Risk Level and Time Period
SELECT
    r.risk_level,
    d.time_period,
    COUNT(*) AS total_transactions,
    SUM(t.is_fraud) AS fraud_transactions,
    ROUND(SUM(t.is_fraud) * 100.0 / COUNT(*), 2) AS fraud_percentage
FROM fact_transaction t
JOIN dim_risk r
    ON t.risk_key = r.risk_key
JOIN dim_time d
    ON t.time_key = d.time_key
GROUP BY r.risk_level, d.time_period
ORDER BY fraud_percentage DESC;