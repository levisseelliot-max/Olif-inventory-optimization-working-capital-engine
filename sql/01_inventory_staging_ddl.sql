-- =============================================================================
-- SCRIPT: 01_inventory_staging_ddl.sql
-- DESCRIPTION: Data Definition Language (DDL) for Inventory Analytics Pipeline
-- DATABASE: Google BigQuery (Standard SQL)
-- ARCHITECTURE LAYER: Staging / Ingestion Zone
-- AUTHOR: Elliot Levisse - Supply Chain & Operations Analytics Practice
-- =============================================================================

-- 1. Create or Verify Dataset Schema
CREATE SCHEMA IF NOT EXISTS `supply_chain_inventory`
OPTIONS (
  location = 'US',
  description = 'Staging and analytical tables for multi-echelon inventory optimization'
);

-- -----------------------------------------------------------------------------
-- 2. Product Catalog & Supplier Master (stg_products)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE `supply_chain_inventory.stg_products` (
  product_id              INT64 OPTIONS(description="Unique SKU numerical identifier"),
  product_name            STRING OPTIONS(description="Commercial SKU description"),
  product_category        STRING OPTIONS(description="Merchandising taxonomy category"),
  unit_cost               NUMERIC OPTIONS(description="Standard inventory acquisition/cogs cost ($)"),
  unit_price              NUMERIC OPTIONS(description="Commercial invoice selling price ($)"),
  supplier_id             STRING OPTIONS(description="Tier-1 vendor identifier"),
  inbound_lead_time_days  INT64 OPTIONS(description="Contractual supplier order-to-delivery lead time in days")
)
CLUSTER BY product_id, product_category;

-- -----------------------------------------------------------------------------
-- 3. Daily Historical Outbound Demand (stg_daily_demand)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE `supply_chain_inventory.stg_daily_demand` (
  order_date              DATE OPTIONS(description="Daily transactional demand consumption date"),
  product_id              INT64 OPTIONS(description="SKU identifier joining to stg_products"),
  units_sold              INT64 OPTIONS(description="Net units shipped to fulfill customer orders"),
  gross_sales_revenue     NUMERIC OPTIONS(description="Invoice value generated ($)")
)
PARTITION BY order_date
CLUSTER BY product_id;

-- -----------------------------------------------------------------------------
-- 4. Current Inventory Snapshot (stg_inventory_snapshot)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE `supply_chain_inventory.stg_inventory_snapshot` (
  snapshot_date           DATE OPTIONS(description="Inventory cycle count audit date"),
  product_id              INT64 OPTIONS(description="SKU identifier joining to stg_products"),
  current_stock_units     INT64 OPTIONS(description="Physical on-hand inventory available in warehouse"),
  stock_in_transit_units  INT64 OPTIONS(description="Open purchase orders confirmed in carrier transit")
)
PARTITION BY snapshot_date
CLUSTER BY product_id;
