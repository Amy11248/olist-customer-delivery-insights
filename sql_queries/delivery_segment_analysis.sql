-- delivery_segment_analysis.sql

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
),
customer_reviews AS (
  SELECT co.customer_unique_id, ore.review_score, o.order_delivered_customer_date, o.order_approved_at,
         DATE_DIFF(o.order_delivered_customer_date, o.order_approved_at, DAY) AS transition_time,
         CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On Time' ELSE 'Late' END AS delivery_status
  FROM customer_order AS co
  JOIN `your_project.order_review` AS ore ON co.order_id = ore.order_id
  JOIN `your_project.orders` AS o ON co.order_id = o.order_id
  WHERE o.order_delivered_customer_date IS NOT NULL
    AND o.order_approved_at IS NOT NULL
    AND DATE_DIFF(o.order_delivered_customer_date, o.order_approved_at, DAY) >= 0
)
SELECT 
  ct.value_segment,
  ROUND(AVG(cr.transition_time), 1) AS avg_transition_days,
  ROUND(COUNTIF(cr.delivery_status = 'On Time') / COUNT(*), 3) AS on_time_rate,
  ROUND(AVG(cr.review_score), 2) AS avg_review_score
FROM customer_reviews AS cr
JOIN customer_tier AS ct ON cr.customer_unique_id = ct.customer_unique_id
GROUP BY ct.value_segment
ORDER BY CASE ct.value_segment
  WHEN 'High Value' THEN 1
  WHEN 'Mid Value' THEN 2
  WHEN 'Low Value' THEN 3
END;
