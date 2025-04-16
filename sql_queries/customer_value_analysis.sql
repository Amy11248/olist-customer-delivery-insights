--customer_value_analysis.sql
-- Calculate total order number and total payment value
WITH customer_order AS (
  SELECT o.order_id, c.customer_unique_id
  FROM `your_project.orders` AS o 
  JOIN `your_project.customers` AS c ON o.customer_id = c.customer_id
),
customer_payments AS (
  SELECT co.customer_unique_id, 
         COUNT(DISTINCT co.order_id) AS total_order,
         ROUND(SUM(op.payment_value), 2) AS total_payment
  FROM `your_project.order_payments` AS op
  JOIN customer_order AS co ON op.order_id = co.order_id
  GROUP BY co.customer_unique_id
),
customer_tier AS (
  SELECT *,
    CASE 
      WHEN total_payment >= 400 THEN 'High Value'
      WHEN total_payment BETWEEN 80 AND 399.99 THEN 'Mid Value'
      ELSE 'Low Value'
    END AS value_segment
  FROM customer_payments
)

-- Customer segmentation metrics
SELECT 
  value_segment,
  COUNT(*) AS customer_count,
  ROUND(AVG(total_payment), 2) AS avg_payment,
  ROUND(AVG(total_order), 2) AS avg_order
FROM customer_tier
GROUP BY value_segment
ORDER BY customer_count DESC;

-- Customer number by state
SELECT 
  c.customer_state,
  ct.value_segment,
  COUNT(*) AS customer_count
FROM customer_tier AS ct
JOIN `your_project.customers` AS c ON ct.customer_unique_id = c.customer_unique_id
GROUP BY c.customer_state, ct.value_segment;

-- Customer number in each segment and payment
WITH tier_summary AS (
  SELECT value_segment,
         COUNT(*) AS customer_count,
         SUM(total_payment) AS total_payment
  FROM customer_tier
  GROUP BY value_segment
),
total_summary AS (
  SELECT 
    SUM(customer_count) AS total_customers,
    SUM(total_payment) AS total_payments
  FROM tier_summary
)
SELECT 
  t.value_segment,
  ROUND(t.customer_count / ts.total_customers * 100, 2) AS customer_pct,
  ROUND(t.total_payment / ts.total_payments * 100, 2) AS payment_pct
FROM tier_summary AS t, total_summary AS ts;

