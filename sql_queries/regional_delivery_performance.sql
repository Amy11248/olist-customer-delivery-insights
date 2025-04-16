-- regional_delivery_performance.sql

WITH orders_customers AS (
  SELECT 
    o.order_id,
    c.customer_state, 
    o.order_delivered_customer_date, 
    o.order_approved_at, 
    o.order_estimated_delivery_date,
    DATE_DIFF(o.order_delivered_customer_date, o.order_approved_at, DAY) AS transition_time,
    CASE 
      WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On Time'
      ELSE 'Late'
    END AS delivery_status
  FROM `your_project.orders` AS o
  JOIN `your_project.customers` AS c ON o.customer_id = c.customer_id
  WHERE o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
    AND DATE_DIFF(o.order_delivered_customer_date, o.order_approved_at, DAY) >= 0
)

SELECT 
  customer_state, 
  COUNT(*) AS order_count,
  ROUND(AVG(transition_time), 2) AS average_TT,
  ROUND(COUNTIF(delivery_status = 'On Time') / COUNT(*), 2) AS on_time_rate
FROM orders_customers
GROUP BY customer_state
ORDER BY order_count DESC;
