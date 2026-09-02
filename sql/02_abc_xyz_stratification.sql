-- =============================================================================
-- SCRIPT: 02_abc_xyz_stratification.sql
-- DESCRIPTION: ABC (Pareto Revenue) and XYZ (Demand Volatility) Segmentation
-- DATABASE: Google BigQuery (Standard SQL)
-- ARCHITECTURE LAYER: Intermediate Analytical Layer
-- AUTHOR: Elliot Levisse - Supply Chain & Operations Analytics Practice
-- =============================================================================

CREATE OR REPLACE VIEW `supply_chain_inventory.v_abc_xyz_stratification` AS

WITH annual_sku_performance AS (
  -- Step 1: Aggregate trailing 365-day demand volume and revenue per SKU
  SELECT
    p.product_id,
    p.product_name,
    p.product_category,
    p.unit_cost,
    p.unit_price,
    p.inbound_lead_time_days,
    COALESCE(SUM(d.units_sold), 0) AS total_annual_units,
    COALESCE(SUM(d.gross_sales_revenue), 0.0) AS total_annual_revenue,
    
    -- Statistical demand variability over observed trading days
    ROUND(AVG(d.units_sold), 4) AS avg_daily_demand,
    ROUND(COALESCE(STDDEV_SAMP(d.units_sold), 0.0), 4) AS std_dev_daily_demand,
    COUNT(DISTINCT d.order_date) AS active_trading_days
  FROM `supply_chain_inventory.stg_products` p
  LEFT JOIN `supply_chain_inventory.stg_daily_demand` d
    ON p.product_id = d.product_id
  GROUP BY
    p.product_id,
    p.product_name,
    p.product_category,
    p.unit_cost,
    p.unit_price,
    p.inbound_lead_time_days
),

pareto_cumulative_revenue AS (
  -- Step 2: Compute cumulative revenue share across active portfolio (Pareto Analysis)
  SELECT
    *,
    SUM(total_annual_revenue) OVER () AS enterprise_gross_revenue,
    SUM(total_annual_revenue) OVER (
      ORDER BY total_annual_revenue DESC, product_id ASC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue,
    
    -- Coefficient of Variation: CV = Standard Deviation / Mean
    ROUND(SAFE_DIVIDE(std_dev_daily_demand, avg_daily_demand), 4) AS coefficient_of_variation
  FROM annual_sku_performance
),

segmented_portfolio AS (
  -- Step 3: Classify ABC classes (Revenue) and XYZ classes (Demand Predictability)
  SELECT
    product_id,
    product_name,
    product_category,
    unit_cost,
    unit_price,
    inbound_lead_time_days,
    total_annual_units,
    total_annual_revenue,
    avg_daily_demand,
    std_dev_daily_demand,
    coefficient_of_variation,
    ROUND(SAFE_DIVIDE(cumulative_revenue, enterprise_gross_revenue) * 100.0, 2) AS cumulative_revenue_share_pct,
    
    -- ABC Revenue Pareto Classification: 80% / 15% / 5%
    CASE
      WHEN SAFE_DIVIDE(cumulative_revenue, enterprise_gross_revenue) <= 0.8000 THEN 'A'
      WHEN SAFE_DIVIDE(cumulative_revenue, enterprise_gross_revenue) <= 0.9500 THEN 'B'
      ELSE 'C'
    END AS abc_class,

    -- XYZ Demand Predictability Matrix (CV threshold benchmark)
    -- X: Stable demand (CV <= 0.50)
    -- Y: Moderate variability (0.50 < CV <= 1.00)
    -- Z: Highly volatile / intermittent (CV > 1.00)
    CASE
      WHEN coefficient_of_variation <= 0.50 THEN 'X'
      WHEN coefficient_of_variation <= 1.00 THEN 'Y'
      ELSE 'Z'
    END AS xyz_class
  FROM pareto_cumulative_revenue
)

-- Step 4: Final output combining multi-echelon segment tags
SELECT
  product_id,
  product_name,
  product_category,
  unit_cost,
  unit_price,
  inbound_lead_time_days,
  total_annual_units,
  total_annual_revenue,
  avg_daily_demand,
  std_dev_daily_demand,
  coefficient_of_variation,
  cumulative_revenue_share_pct,
  abc_class,
  xyz_class,
  CONCAT(abc_class, xyz_class) AS abc_xyz_segment
FROM segmented_portfolio;
