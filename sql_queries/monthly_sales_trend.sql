-- monthly_sales_trend.sql
WITH orders_past AS (
  SELECT  
    DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) AS order_month,
    ROUND(SUM(op.payment_value), 2) AS payment_value_by_month,
    COUNT(*) AS order_by_month
  FROM `your_project.orders` AS o
  JOIN `your_project.order_payments` AS op
    ON o.order_id = op.order_id
  WHERE o.order_status IN ('delivered', 'shipped')
  GROUP BY DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH)
  ORDER BY order_month
),
order_past_12_month AS (
  SELECT order_month, payment_value_by_month, order_by_month
  FROM orders_past
  WHERE order_month > DATE_SUB(DATE '2018-10-17', INTERVAL 13 MONTH)
),
order_previous_month AS (
  SELECT 
    order_month, 
    payment_value_by_month, 
    order_by_month,
    LAG(payment_value_by_month) OVER(ORDER BY order_month) AS prev_month_payment
  FROM order_past_12_month
)
SELECT 
  order_month,
  payment_value_by_month,
  order_by_month,
  ROUND((payment_value_by_month - prev_month_payment) / prev_month_payment, 2) AS mom_growth
FROM order_previous_month
ORDER BY order_month;
