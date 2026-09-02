-- =============================================================================
-- SCRIPT: 03_dynamic_rop_safety_stock.sql
-- DESCRIPTION: Reorder Point (ROP) Engine, Safety Stock & 50% What-If Simulation
-- DATABASE: Google BigQuery (Standard SQL)
-- ARCHITECTURE LAYER: Dimensional Production Fact Table
-- AUTHOR: Elliot Levisse - Supply Chain & Operations Analytics Practice
-- =============================================================================

CREATE OR REPLACE TABLE `supply_chain_inventory.fact_inventory_replenishment` AS

WITH baseline_service_levels AS (
  -- Step 1: Assign Cycle Service Level (CSL) and Z-score based on ABC stratification
  -- Class A: 98% Service Level (Z = 2.054) - Revenue drivers protected
  -- Class B: 92% Service Level (Z = 1.405) - Volume core re-balanced
  -- Class C: 85% Service Level (Z = 1.036) - Tail lines de-buffered
  SELECT
    seg.*,
    inv.current_stock_units,
    inv.stock_in_transit_units,
    CASE
      WHEN seg.abc_class = 'A' THEN 2.054
      WHEN seg.abc_class = 'B' THEN 1.405
      ELSE 1.036
    END AS z_factor_service_level,
    
    -- Carrying Cost Proxy: 25% annual holding rate
    0.25 AS annual_holding_cost_rate
  FROM `supply_chain_inventory.v_abc_xyz_stratification` seg
  INNER JOIN `supply_chain_inventory.stg_inventory_snapshot` inv
    ON seg.product_id = inv.product_id
),

stochastic_reorder_calculations AS (
  -- Step 2: Compute Baseline Safety Stock (SS) and Reorder Point (ROP)
  -- Formula: SS = Z * std_dev_demand * SQRT(Lead_Time)
  -- Formula: ROP = (avg_daily_demand * Lead_Time) + SS
  SELECT
    *,
    -- Baseline Safety Stock (Units)
    ROUND(
      z_factor_service_level * std_dev_daily_demand * SQRT(inbound_lead_time_days)
    ) AS baseline_safety_stock_units,
    
    -- Baseline Reorder Point (Units)
    ROUND(
      (avg_daily_demand * inbound_lead_time_days) + 
      (z_factor_service_level * std_dev_daily_demand * SQRT(inbound_lead_time_days))
    ) AS baseline_reorder_point_units,
    
    -- What-If Scenario: 50% Lead Time Compression (Simulation Parameter)
    ROUND(inbound_lead_time_days * 0.50, 2) AS simulated_lead_time_days,
    ROUND(
      z_factor_service_level * std_dev_daily_demand * SQRT(inbound_lead_time_days * 0.50)
    ) AS simulated_safety_stock_units
  FROM baseline_service_levels
),

operational_status_flagging AS (
  -- Step 3: Flag Operational Replenishment Alerts and Capital Deployments
  SELECT
    product_id,
    product_name,
    product_category,
    abc_class,
    xyz_class,
    abc_xyz_segment,
    unit_cost,
    inbound_lead_time_days,
    current_stock_units,
    baseline_safety_stock_units,
    baseline_reorder_point_units,
    simulated_safety_stock_units,
    
    -- Balance Sheet: Baseline Working Capital tied in physical inventory
    ROUND(current_stock_units * unit_cost, 2) AS baseline_working_capital,
    
    -- P&L: Annual inventory carrying cost (25% rate)
    ROUND((current_stock_units * unit_cost) * annual_holding_cost_rate, 2) AS baseline_annual_holding_cost,

    -- Replenishment Alert Logic:
    -- 1. CRITICAL STOCKOUT RISK (Red): Current Stock <= Safety Stock
    -- 2. REORDER REQUIRED (Yellow): Safety Stock < Current Stock <= ROP
    -- 3. OPTIMAL BUFFER (Green): Current Stock > ROP
    CASE
      WHEN current_stock_units <= baseline_safety_stock_units THEN '🔴 CRITICAL STOCKOUT RISK'
      WHEN current_stock_units <= baseline_reorder_point_units THEN '🟡 REORDER REQUIRED'
      ELSE '🟢 OPTIMAL BUFFER'
    END AS replenishment_alert_status,

    -- Suggested Order Quantity: Gap to bring stock back to ROP target
    CASE
      WHEN current_stock_units < baseline_reorder_point_units 
      THEN CAST((baseline_reorder_point_units - current_stock_units) AS INT64)
      ELSE 0
    END AS suggested_order_units,

    -- Suggested Purchase Budget Commitment ($)
    CASE
      WHEN current_stock_units < baseline_reorder_point_units 
      THEN ROUND((baseline_reorder_point_units - current_stock_units) * unit_cost, 2)
      ELSE 0.00
    END AS suggested_order_cost,

    -- What-If Simulation Metrics:
    -- Simulated Working Capital = Preserved Cycle Stock + Simulated Safety Stock
    ROUND(
      ((current_stock_units - baseline_safety_stock_units) + simulated_safety_stock_units) * unit_cost, 
      2
    ) AS simulated_working_capital,

    -- Permanent Liquidity Released = (Baseline SS - Simulated SS) * Unit Cost
    ROUND(
      (baseline_safety_stock_units - simulated_safety_stock_units) * unit_cost, 
      2
    ) AS working_capital_released,

    -- Annual P&L Carrying Cost Savings = Released Working Capital * 25%
    ROUND(
      ((baseline_safety_stock_units - simulated_safety_stock_units) * unit_cost) * annual_holding_cost_rate, 
      2
    ) AS annual_holding_cost_savings
  FROM stochastic_reorder_calculations
)

-- Step 4: Final Analytical Fact Table exposed to Tableau Extract
SELECT
  product_id,
  product_name,
  product_category,
  abc_class,
  xyz_class,
  abc_xyz_segment,
  unit_cost,
  inbound_lead_time_days,
  current_stock_units,
  baseline_safety_stock_units,
  baseline_reorder_point_units,
  baseline_working_capital,
  baseline_annual_holding_cost,
  replenishment_alert_status,
  suggested_order_units,
  suggested_order_cost,
  simulated_working_capital,
  working_capital_released,
  annual_holding_cost_savings
FROM operational_status_flagging;
