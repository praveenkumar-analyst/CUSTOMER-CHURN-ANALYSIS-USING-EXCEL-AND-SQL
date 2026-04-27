# Customer Churn Analysis

**Tools:** SQL Server · Power BI · Excel  
**Domain:** Telecom / Subscription Business  
**Records Analyzed:** 100,000+ customer records

---

## Project Overview

This project analyzes customer churn behavior across a telecom dataset of 100,000+ records. Using SQL Server for data extraction and transformation, I identified key churn drivers across customer tenure, usage frequency, and billing history. The findings were visualized in a Power BI dashboard to help the retention team target high-risk customer segments.

---

## Business Problem

A telecom company was experiencing high customer churn with no clear visibility into *who* was leaving or *why*. The goal was to:
- Identify patterns in churned vs. retained customers
- Segment customers by churn risk level (High / Mid / Low)
- Provide actionable insights to the retention team

---

## Dataset Description

**File:** `customer_churn_dataset.csv`  
**Rows:** 100,000 customer records  
**Source:** Simulated telecom dataset

| Column | Description |
|--------|-------------|
| customer_id | Unique customer identifier |
| tenure_months | Number of months the customer has been active |
| contract_type | Month-to-Month / One Year / Two Year |
| monthly_charges | Monthly bill amount (₹) |
| total_charges | Total amount billed to date (₹) |
| payment_method | Auto Pay / Manual / Bank Transfer / Credit Card |
| usage_frequency | Number of service interactions per month |
| support_tickets | Number of support tickets raised in last 6 months |
| internet_service | DSL / Fiber Optic / No |
| churn | 1 = Churned, 0 = Retained |

---

## SQL Analysis

**File:** `churn_analysis_queries.sql`

### Queries Covered:
1. Overall churn rate
2. Churn by contract type
3. Churn by tenure band (using CTEs)
4. High-risk customer identification (using Window Functions)
5. Average charges — churned vs retained
6. Churn by payment method
7. Top churned segments by usage frequency
8. Rolling churn trend by month

---

## Key Findings

| Insight | Finding |
|--------|---------|
| Overall Churn Rate | ~26.5% |
| Highest churn group | Month-to-Month contract customers |
| Lowest churn group | Two-year contract customers (< 5%) |
| Tenure risk zone | Customers with tenure < 12 months churn 3x more |
| Billing trigger | Customers with monthly charges > ₹70 churn 40% more |
| Support tickets | Customers with 3+ tickets have 58% churn rate |

---

## Power BI Dashboard

The dashboard includes:
- **Churn Rate KPI Card** — overall and by segment
- **Churn by Contract Type** — bar chart
- **Churn by Tenure Band** — histogram
- **High-Risk Customer Table** — filterable by region/contract
- **Monthly Charges vs Churn** — scatter plot
- **Retention Opportunity Map** — heat map by risk tier

---

## Project Structure

```
customer-churn-analysis/
│
├── README.md                        ← You are here
├── customer_churn_dataset.csv       ← Dataset (100K records)
├── churn_analysis_queries.sql       ← All SQL queries with results
└── churn_analysis_excel.xlsx        ← Excel analysis + pivot tables
```

---

## How to Run

**SQL:**
1. Import `customer_churn_dataset.csv` into SQL Server as `customer_churn`
2. Open `churn_analysis_queries.sql` in SQL Server Management Studio (SSMS)
3. Run queries section by section

**Excel:**
1. Open `churn_analysis_excel.xlsx`
2. Each sheet contains a separate analysis with pivot tables and charts

---

## Skills Demonstrated

- Advanced SQL: CTEs, Window Functions (ROW_NUMBER, NTILE, LAG), CASE statements
- Data Cleaning: NULL handling, type casting, deduplication
- Segmentation: RFM-style churn risk scoring
- Power BI: DAX measures, KPI cards, drill-through filters
- Excel: Pivot Tables, COUNTIFS, AVERAGEIFS, conditional formatting

---

## Connect

**LinkedIn:** [linkedin.com/in/praveen-kumar-58055231b](https://linkedin.com/in/praveen-kumar-58055231b)  
**GitHub:** [github.com/praveenkumar-analyst](https://github.com/praveenkumar-analyst)
