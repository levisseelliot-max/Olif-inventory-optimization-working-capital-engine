# 📖 Inventory Optimization & Working Capital KPI Dictionary

> **Mathematical Formulations · Operational Thresholds · BigQuery SQL Logic · Financial Valuation**

| **Project** | Dynamic Inventory Optimization, Safety Stock Simulation & Working Capital Release |
|---|---|
| **Target Scope** | Active commercial catalog of **118 SKUs** |
| **Primary Engine** | Google BigQuery — `fact_inventory_replenishment` |
| **Reporting Suite** | Tableau Executive Cockpit — Tabs 1, 2 & 3 |
| **Annual Holding Cost Rate** | **25.0%** per annum (`h = 0.25`) |

---

## 📌 Purpose

This KPI dictionary defines the mathematical, operational, SQL, and financial logic used by the inventory optimization model.

- Demand and inbound planning
- ABC/XYZ inventory segmentation
- Safety stock and reorder point calculations
- Procurement alert logic
- Working capital valuation
- Holding cost measurement
- Lead-time reduction simulations
- Tableau KPI mapping

---

# 1. 📦 Operational Demand & Inbound Metrics

## 1.1 Average Daily Demand — `d̄`

**Business Definition:** Mean daily outbound unit consumption over the trailing **365-day observed trading period**.

**Formula**

$$
\bar{d} = \frac{1}{N} \sum_{t=1}^{N} d_t
$$

**BigQuery SQL**

```sql
ROUND(AVG(units_sold), 4) AS avg_daily_demand
```

**Operational Role:** Drives cycle stock requirements and base replenishment sizing during supplier lead times.

---

## 1.2 Daily Demand Standard Deviation — `σd`

**Business Definition:** Sample standard deviation measuring day-to-day volatility in unit sales consumption.

**Formula**

$$
\sigma_d = \sqrt{\frac{1}{N-1} \sum_{t=1}^{N}(d_t-\bar{d})^2}
$$

**BigQuery SQL**

```sql
ROUND(
    COALESCE(STDDEV_SAMP(units_sold), 0.0),
    4
) AS std_dev_daily_demand
```

**Operational Role:** Quantifies stochastic demand uncertainty and establishes the statistical basis for safety buffers.

---

## 1.3 Inbound Lead Time — `L`

**Business Definition:** Contractual elapsed duration, in integer calendar days, from purchase order confirmation to receipt and staging in the distribution center.

**SQL Field:** `inbound_lead_time_days` (`INTEGER`)

**Operational Role:** Direct driver of the exposure window during which stockout vulnerabilities exist.

---

## 1.4 Coefficient of Variation — `CV`

**Business Definition:** Normalized dispersion metric expressing demand standard deviation relative to mean consumption.

**Formula**

$$
CV = \frac{\sigma_d}{\bar{d}}
$$

**BigQuery SQL**

```sql
ROUND(
    SAFE_DIVIDE(std_dev_daily_demand, avg_daily_demand),
    4
) AS coefficient_of_variation
```

| **Demand Profile** | **CV Range** | **Interpretation** |
|---|---:|---|
| 🟢 **Stable / Predictable** | `CV ≤ 0.50` | Low demand uncertainty |
| 🟡 **Moderate Variability** | `0.50 < CV ≤ 1.00` | Moderate volatility |
| 🔴 **High Volatility / Intermittent** | `CV > 1.00` | High demand uncertainty |

---

# 2. 🎯 Multi-Echelon Stratification Metrics

## 2.1 ABC Revenue Pareto Classification

**Business Definition:** Segmentation based on cumulative sales revenue distribution over a **365-day cycle**.

| **Class** | **Revenue Contribution** | **Strategic Interpretation** |
|---|---:|---|
| 🅰️ **Class A** | Top **80%** | High-velocity commercial drivers requiring tight oversight |
| 🅱️ **Class B** | Next **15%** | Core operational volume carrying substantial working capital |
| 🅲️ **Class C** | Tail **5%** | Slow-moving catalog subject to minimum stock rationalization |

**BigQuery SQL**

```sql
CASE
    WHEN SAFE_DIVIDE(cumulative_revenue, enterprise_gross_revenue) <= 0.8000 THEN 'A'
    WHEN SAFE_DIVIDE(cumulative_revenue, enterprise_gross_revenue) <= 0.9500 THEN 'B'
    ELSE 'C'
END AS abc_class
```

## 2.2 XYZ Demand Predictability Stratification

| **Class** | **CV Range** | **Interpretation** |
|---|---:|---|
| 🟢 **Class X** | `CV ≤ 0.50` | High forecast accuracy; candidates for lean safety buffers |
| 🟡 **Class Y** | `0.50 < CV ≤ 1.00` | Moderate volatility requiring dynamic buffer adjustments |
| 🔴 **Class Z** | `CV > 1.00` | Erratic/intermittent demand requiring strict exposure caps |

## 2.3 Strategic ABC/XYZ Matrix Segment

**Business Definition:** Nine-cell interaction matrix combining revenue criticality and demand uncertainty.

Examples: `AX`, `BX`, `CY`.

```sql
CONCAT(abc_class, xyz_class) AS abc_xyz_segment
```

---

# 3. 🛡️ Stochastic Buffer & Replenishment Logic

## 3.1 Cycle Service Level — `CSL` & Z-Score

| **ABC Tier** | **Target CSL** | **Z-Factor** |
|---|---:|---:|
| 🅰️ Class A | **98.0%** | **2.054** |
| 🅱️ Class B | **92.0%** | **1.405** |
| 🅲️ Class C | **85.0%** | **1.036** |

## 3.2 Baseline Safety Stock — `SS_base`

**Formula**

$$
SS_{base}=\left\lceil Z \times \sigma_d \times \sqrt{L}\right\rceil
$$

```sql
ROUND(
    z_factor_service_level
    * std_dev_daily_demand
    * SQRT(inbound_lead_time_days)
) AS baseline_safety_stock_units
```

## 3.3 Dynamic Reorder Point — `ROP`

**Formula**

$$
ROP=(\bar{d}\times L)+SS_{base}
$$

```sql
ROUND(
    (avg_daily_demand * inbound_lead_time_days)
    + baseline_safety_stock_units
) AS baseline_reorder_point_units
```

## 3.4 Replenishment Alert Status

| **Status** | **Logical Condition** | **Operational Urgency** |
|---|---|---|
| 🔴 **CRITICAL STOCKOUT RISK** | `Current Stock ≤ SS_base` | Safety buffer breached; expedited order required |
| 🟡 **REORDER REQUIRED** | `SS_base < Current Stock ≤ ROP` | Standard purchase order required |
| 🟢 **OPTIMAL BUFFER** | `Current Stock > ROP` | Healthy buffer; zero immediate order |

## 3.5 Suggested Order Quantity — `Q_sugg`

$$
Q_{sugg}=\max(0,ROP-Current\ Stock)
$$

## 3.6 Suggested Reorder Budget — `C_sugg`

$$
C_{sugg}=Q_{sugg}\times Unit\ Cost
$$

| **Requirement** | **Portfolio Baseline** |
|---|---:|
| 🔴 Critical Stockout | **$379,561** |
| 🟡 Reorder Required | **$62,169** |
| **Total Reorder Budget** | **$441,730** |

---

# 4. 💰 Balance Sheet & Carrying Cost Valuation

## 4.1 Baseline Working Capital — `WC_base`

$$
WC_{base}=\sum_{i=1}^{K}(Current\ Stock\ Units_i\times Unit\ Cost_i)
$$

> **Portfolio Baseline:** **$1,007,896 across 118 active SKUs**

## 4.2 Annual Inventory Holding Cost — `HC_base`

Includes cost of capital, warehouse storage, insurance, shrinkage, and obsolescence at a **25% annual carrying rate**.

$$
HC_{base}=WC_{base}\times0.25
$$

> **Portfolio Baseline:** **$251,974 / year**

## 4.3 Weighted Portfolio Service Level

**Business Definition:** Portfolio-wide service level weighted by gross annual revenue contribution.

> **Baseline:** **91.15%**  
> **Target:** **≥ 96.00%**

---

# 5. 🔄 What-If Simulation & Cash Release Mechanics

## 5.1 Simulated Inbound Lead Time — `L_sim`

$$
L_{sim}=L\times(1-Reduction\%)
$$

## 5.2 Simulated Safety Stock — `SS_sim`

$$
SS_{sim}=\left\lceil Z\times\sigma_d\times\sqrt{L_{sim}}\right\rceil
$$

## 5.3 Permanent Working Capital Released — `ΔWC`

$$
\Delta WC=
\sum_{i=1}^{K}
[(SS_{base,i}-SS_{sim,i})\times Unit\ Cost_i]
$$

> 💵 **50% Lead-Time Reduction → +$51,150 permanent cash release**

## 5.4 Recurring Annual Holding Cost Savings — `ΔHC`

$$
\Delta HC=\Delta WC\times0.25
$$

> 📈 **50% Lead-Time Reduction → +$12,787.50 / year recurring savings**

---

# 6. 📊 Summary Metric Mapping — Tableau ↔ BigQuery

| **Metric Label** | **Tableau Display Name** | **BigQuery Source / Logic** | **Baseline Value** | **Target / Simulated** |
|---|---|---|---:|---:|
| **Active Catalog** | **Active SKU Portfolio** | `COUNT(DISTINCT product_id)` | **118 SKUs** | **118 SKUs** |
| **Working Capital** | **Baseline Working Capital** | `baseline_working_capital` | **$1,007,896** | **$956,746** |
| **Holding Cost** | **Annual Holding Cost (25%)** | `baseline_annual_holding_cost` | **$251,974/yr** | **$239,187/yr** |
| **Service Level** | **Weighted Service Level** | Calculated aggregation | **91.15%** | **≥ 96.00%** |
| **Gross Order Need** | **Total Reorder Budget** | `SUM(suggested_order_cost)` | **$441,730** | **Tranche prioritized** |
| **Critical Breaches** | **Critical Stockouts** | `COUNTIF(status = '...')` 🔴 | **24 SKUs** | **0 SKUs** |
| **Reorder Breaches** | **Reorder Required** | `COUNTIF(status = '...')` 🟡 | **37 SKUs** | **0 SKUs** |
| **Cash Released** | **Working Capital Released** | `working_capital_released` | **$0.00** | **+$51,150** |
| **EBITDA Savings** | **Annual Holding Cost Savings** | `annual_holding_cost_savings` | **$0.00** | **+$12,787/yr** |

---

# 7. 🧭 KPI Decision Flow

```text
DEMAND & SUPPLY SIGNALS
        │
        ├── Average Daily Demand
        ├── Demand Volatility
        ├── Coefficient of Variation
        └── Inbound Lead Time
        │
        ▼
INVENTORY POLICY
        │
        ├── ABC Classification
        ├── XYZ Classification
        ├── Service-Level Target
        ├── Safety Stock
        └── Reorder Point
        │
        ▼
PROCUREMENT ACTION
        │
        ├── Critical Stockout
        ├── Reorder Required
        ├── Suggested Order Quantity
        └── Reorder Budget
        │
        ▼
FINANCIAL OUTCOME
        │
        ├── Working Capital
        ├── Holding Cost
        ├── Cash Released
        └── EBITDA Savings
```

---

## 🎯 Executive KPI Reference

| **KPI** | **Baseline** | **Target / Simulation** | **Strategic Meaning** |
|---|---:|---:|---|
| **Working Capital** | **$1,007,896** | **$956,746** | **-$51,150** permanent cash release |
| **Annual Holding Cost** | **$251,974** | **$239,187** | **+$12,787/yr** direct EBITDA accretion |
| **Critical Stockouts** | **24 SKUs** | **0 SKUs** | Eliminate immediate supply vulnerability |
| **Weighted Service Level** | **91.15%** | **≥ 96.00%** | Protect revenue and margin drivers |
| **Total Reorder Budget** | **$441,730** | Tranche prioritized | Capital-constrained procurement execution |

---

> **North Star:** Convert inventory data into procurement decisions that simultaneously protect service levels, reduce stockout exposure, and release trapped working capital.

*Inventory Optimization & Working Capital KPI Data Dictionary · 118 active SKUs · BigQuery · Tableau Executive Cockpit*
