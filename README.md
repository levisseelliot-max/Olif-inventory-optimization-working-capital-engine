# 📦 Dynamic Inventory Optimization, Safety Stock Simulation & Working Capital Release
### *End-to-End Analytics Pipeline, ABC/XYZ Stratification & $51.1k Cash-Release Engine*

![Data Warehouse](https://img.shields.io/badge/Data%20Warehouse-Google%20BigQuery-4285F4?style=flat&logo=googlecloud&logoColor=white)
![Analytics](https://img.shields.io/badge/Analytics-Dynamic%20ROP%20%26%20Safety%20Stock-blue?style=flat)
![Business Intelligence](https://img.shields.io/badge/BI-Tableau%20Desktop%20%26%20Cloud-E97627?style=flat&logo=tableau&logoColor=white)
![Impact](https://img.shields.io/badge/Cash%20Released-$51.1k-success?style=flat)
![Carrying Cost Savings](https://img.shields.io/badge/Holding%20Cost%20Savings-$12.8k%2Fyr-teal?style=flat)

---

## 🎯 Executive Overview & Investment Thesis

Managing working capital efficiently is the core lever of supply chain profitability. Across an active commercial catalog of **118 SKUs**, baseline operations tie up **$1,007,896 in working capital**, incurring **$251,974 in annual inventory carrying costs** (25% holding rate) while masking extreme operational risk: **24 SKUs (20.3%) are in critical stockout breach** and **37 SKUs (31.4%) require urgent reordering**, demanding a gross cash injection of **$441,730**.

This project provides an end-to-end data pipeline from BigQuery SQL modeling of stochastic demand to an interactive executive Tableau Cockpit diagnosing structural over-buffering and modeling a targeted operational turnaround.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    BASELINE STATE (118 Active SKUs)                         │
│  $1,007,896 Working Capital │ $251,974 Annual Holding Cost (25% Carrying)   │
│  91.15% Weighted Service Level │ 24 Critical Stockouts ($441,730 Budget)    │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                      STRATEGIC INTERVENTION (3 PILLARS)
           1. Dynamic Safety Stock & ROP Reset (ABC/XYZ Stratification)
           2. Inbound Lead-Time Compression & Vendor SLAs (-50% Lead Time)
           3. Capital-Constrained Purchase Batching on Critical Revenue Lines
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                 SIMULATED TARGET STATE (-50% LEAD TIME)                     │
│  $956,746 Working Capital Target │ $51,150 Permanent Cash Released          │
│  $12,787/yr Recurring P&L Savings │ 100% Stockout Resolution on Class A/B   │
└─────────────────────────────────────────────────────────────────────────────┘
```

Strategic Mandate: Execute a phased $441,730 procurement deployment prioritized by unit margin and critical stockout risk, combined with a 50% inbound lead-time reduction initiative that permanently unlocks $51,150 in balance-sheet liquidity and captures $12,787 in recurring annual EBITDA savings.

## 🛠️ Architecture & Technology Stack

```
[ Raw Transactional Data ] 
          │
          ▼  (BigQuery SQL CTEs & Window Functions)
[ Demand Variability & Lead Time Modeling ] ──> stg_inventory_demand_metrics
          │
          ▼  (ABC/XYZ Stratification & Dynamic ROP Calculations)
[ Analytical Fact Layer ] ────────────────────> fact_inventory_replenishment
          │
          ▼  (Fast-Query Tableau Extract Engine)
[ Executive 3-Tab BI Suite ] ─────────────────> C-Level Decision Memorandum (A3 Briefing)
```

- **Data Warehouse & Data Engineering:** Google BigQuery (Standard SQL, Statistical Window Functions, Safe Division, Conditional Aggregations)
- **Mathematical & Operational Models:**
    - **ABC/XYZ Matrix:** Stratifying revenue contribution (Pareto 80/15/5) and demand coefficient of variation ($CV$).
    - **Dynamic Safety Stock:** $SS = Z \times \sigma_d \times \sqrt{L}$ calibrated per service level target.
    - **Reorder Point ($ROP$):** $ROP = (\bar{d} \times L) + SS$.
- **Business Intelligence:** Tableau Desktop & Cloud (Cross-filtering, Dual-axis bar-in-bar charts, Interactive what-if parameter modeling).
- **Financial Modeling:** Inventory holding cost attribution (25% annual carrying rate) and balance-sheet cash release mechanics.

## 🔍 Diagnostic & Analytical Insights

### 1. The Class B Over-Buffering Trap (ABC/XYZ Stratification)
- Conventional operations focus inventory governance almost exclusively on Class A. However, our diagnostic reveals that **Class B absorbs $771,060 (76.5%) of enterprise working capital**.

- The **BX segment** (moderate revenue, highly predictable demand) accounts for **$153.7K in annual holding overhead**. Because demand predictability is high, this inventory represents defensive over-buffering driven by vendor lead-time conservatism rather than market volatility.


### 2. Immediate Operational Fragility ($441,730 Reorder Deficit)
- **51.7% of the entire portfolio is in immediate supply breach:**
  - 🔴 **24 SKUs (Critical Stockout Risk):** Current on-hand stock has pierced safety stock levels, requiring $379,561.

  - 🟡 **37 SKUs (Reorder Required):** On-hand stock is below ROP, requiring $62,169.

- **Pareto Concentration of Capital Deficit:** 71.8% of the gross reorder budget is concentrated in just 3 SKUs:

1. _Lawn Mower (SKU 1355):_ 100 on hand vs. 379 ROP. **Order Cost: $148,590** (33.6% of total budget).

2. _Children’s Heaters (SKU 1350):_ 96 on hand vs. 357 ROP. **Order Cost: $93,203** (21.1% of total budget).

3. _Smart Watch (SKU 1360):_ 86 on hand vs. 300 ROP. **Order Cost: $70,139** (15.9% of total budget).
   

### 3. What-If Simulation: Compressing Lead Time by 50%
- Contractually compressing supplier lead times by 50% structurally deflates safety stock requirements:

  - **Net Working Capital Released: +$51,150** returned permanently to cash reserves.

  - **Recurring Holding Cost Reduction: +$12,787/year** direct EBITDA accretion.

  - **Top Single Beneficiary:** _Dell Laptop (SKU 1351)_ alone yields **$2,306/yr** in holding cost reduction ($9,224 cash unlocked).
    

## 📊 Tableau BI Suite Walkthrough

| **Dashboard Tab**                       | **Key Visual Components**                                                                                                                                                                 | **Strategic Objective**                                                                                                   |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Tab 1: Executive Inventory Overview** | • BANs: Working Capital ($1.01M), Holding Cost ($252k), Service Level (91.15%), Active SKUs (118)<br>• Strategic ABC/XYZ Matrix (Holding Cost Heatmap)<br>• Interactive SKU Detail Ledger | C-Suite visibility into capital allocation imbalances and carrying cost concentration across demand predictability tiers. |
| **Tab 2: Operational Reorder Engine**   | • BANs: Total Reorder Budget ($441.7k), Critical Breaches (24), Reorder Items (37)<br>• Stock vs. ROP Bar-in-Bar Threshold Visualizer<br>• Dynamic Reorder Action Table (Units & Value)   | Daily operational cockpit for procurement teams, prioritizing purchase order issuance by capital exposure.                |
| **Tab 3: What-If Scenario Simulator**   | • Dynamic Lead Time Reduction Parameter Slider (0%–100%)<br>• Real-time Recalculated BANs (Cash Released & Holding Savings)<br>• ABC Working Capital Comparison & Top 10 Beneficiary SKUs | Negotiation sandbox for supply chain leaders to quantify balance-sheet ROI before vendor SLA renegotiation.               |

---

## 🚀 Strategic Recommendations & Implementation Roadmap

| **Pillar**   | **Strategic Lever**               | **Operational Mechanism**                                                                       | **Financial & Operational Impact**                                                              |
| ------------ | --------------------------------- | ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| **Pillar 1** | **Safety Stock Realignment**      | Differentiate service levels: **98% for Class A, 92% for Class B, 85% for Class C**             | Immediately deflates **$35,280** in excess Class B buffer stock.                                |
| **Pillar 2** | **Inbound Lead Time Compression** | Contractual SLA enforcement and vendor stocking programs (**-50% lead time**)                   | Permanently unlocks **$51,150 in cash** and saves **$12,787/yr in carrying costs**.             |
| **Pillar 3** | **Tranche-Based Procurement**     | Split **$441.7k** reorder into Tranche 1 (Top 3 lines: **$311.9k**) and Tranche 2 (**$129.8k**) | Eliminates **100% of revenue stockout threats** while containing monthly working capital drain. |

---

## 📁 Repository Structure

```text
├── sql/
│   ├── 01_inventory_staging_ddl.sql          # Table schemas & data ingestion pipelines
│   ├── 02_abc_xyz_stratification.sql         # Revenue Pareto & demand volatility modeling
│   └── 03_dynamic_rop_safety_stock.sql       # Safety stock formulas & ROP alert engine
├── docs/
│   ├── Executive_Memorandum_A3.md            # C-Suite Decision Note & Investment Briefing
│   └── Inventory_KPI_Dictionary.md           # Business definitions & operational formulas
├── tableau/
│   └── Inventory_Optimization_Suite.twbx     # Packaged Tableau Workbook (3 Executive Tabs)
└── README.md                                 # Executive Project Showcase & ROI Diagnostic
```

---

## 👤 Author & Contact

**Elliot Levisse** — *Supply Chain & Operations Analytics Specialist*

* 🎓 Master of Science in Supply Chain & Business Organization — **IÉSEG School of Management**
* 📦 Specialized in inventory modeling, operational turnaround, and BI decision cockpits.
* 🔗 **LinkedIn:** [linkedin.com/in/elliotlevisse](https://www.linkedin.com/in/elliot-levisse/)
* 💻 **GitHub:** [github.com/elliotlevisse-max](https://github.com/levisseelliot-max)
