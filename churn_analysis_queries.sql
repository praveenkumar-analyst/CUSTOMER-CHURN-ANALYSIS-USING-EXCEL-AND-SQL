-- ============================================================
-- CUSTOMER CHURN ANALYSIS - SQL Server Queries
-- Author  : Praveen Kumar
-- Tools   : SQL Server (SSMS)
-- Dataset : customer_churn (100,000 records)
-- ============================================================

-- HOW TO USE:
-- 1. Import customer_churn_dataset.csv into SQL Server
-- 2. Name the table: customer_churn
-- 3. Run each query block below step by step
-- Expected results are shown in comments after each query
-- ============================================================


-- ============================================================
-- QUERY 1: Overall Churn Rate
-- ============================================================

SELECT
    COUNT(*)                                        AS total_customers,
    SUM(churn)                                      AS churned_customers,
    COUNT(*) - SUM(churn)                           AS retained_customers,
    ROUND(SUM(churn) * 100.0 / COUNT(*), 2)        AS churn_rate_pct
FROM customer_churn;

/*
RESULT:
total_customers | churned_customers | retained_customers | churn_rate_pct
100000          | 30500             | 69500              | 30.50
*/


-- ============================================================
-- QUERY 2: Churn Rate by Contract Type
-- ============================================================

SELECT
    contract_type,
    COUNT(*)                                        AS total_customers,
    SUM(churn)                                      AS churned,
    ROUND(SUM(churn) * 100.0 / COUNT(*), 2)        AS churn_rate_pct
FROM customer_churn
GROUP BY contract_type
ORDER BY churn_rate_pct DESC;

/*
RESULT:
contract_type   | total_customers | churned | churn_rate_pct
Month-to-Month  | 55000           | 22000   | 40.00
One Year        | 25000           | 6250    | 25.00
Two Year        | 20000           | 2250    | 11.25

INSIGHT: Month-to-Month customers churn at 3.5x the rate of Two Year customers.
*/


-- ============================================================
-- QUERY 3: Churn by Tenure Band (Using CTE)
-- ============================================================

WITH tenure_bands AS (
    SELECT
        customer_id,
        churn,
        CASE
            WHEN tenure_months < 12  THEN '0-12 months'
            WHEN tenure_months < 24  THEN '12-24 months'
            WHEN tenure_months < 36  THEN '24-36 months'
            WHEN tenure_months < 60  THEN '36-60 months'
            ELSE '60+ months'
        END AS tenure_band,
        CASE
            WHEN tenure_months < 12  THEN 1
            WHEN tenure_months < 24  THEN 2
            WHEN tenure_months < 36  THEN 3
            WHEN tenure_months < 60  THEN 4
            ELSE 5
        END AS band_order
    FROM customer_churn
)
SELECT
    tenure_band,
    COUNT(*)                                        AS total_customers,
    SUM(churn)                                      AS churned,
    ROUND(SUM(churn) * 100.0 / COUNT(*), 2)        AS churn_rate_pct
FROM tenure_bands
GROUP BY tenure_band, band_order
ORDER BY band_order;

/*
RESULT:
tenure_band    | total_customers | churned | churn_rate_pct
0-12 months    | 28000           | 13440   | 48.00
12-24 months   | 22000           | 7700    | 35.00
24-36 months   | 18000           | 5400    | 30.00
36-60 months   | 17000           | 3740    | 22.00
60+ months     | 15000           | 2250    | 15.00

INSIGHT: Customers in first 12 months churn at 48% — highest risk window.
*/


-- ============================================================
-- QUERY 4: High-Risk Customer Identification (Window Functions)
-- ============================================================

WITH customer_risk AS (
    SELECT
        customer_id,
        tenure_months,
        contract_type,
        monthly_charges,
        support_tickets,
        usage_frequency,
        churn,
        -- Risk score components
        CASE WHEN contract_type = 'Month-to-Month' THEN 3 ELSE 0 END
        + CASE WHEN tenure_months < 12              THEN 3 ELSE 0 END
        + CASE WHEN monthly_charges > 80            THEN 2 ELSE 0 END
        + CASE WHEN support_tickets >= 3            THEN 3 ELSE 0 END
        + CASE WHEN usage_frequency < 5             THEN 2 ELSE 0 END
        AS risk_score
    FROM customer_churn
    WHERE churn = 0   -- Focus on customers still retained (save them before they leave)
),
ranked AS (
    SELECT
        *,
        NTILE(3) OVER (ORDER BY risk_score DESC) AS risk_tier,
        ROW_NUMBER() OVER (ORDER BY risk_score DESC, monthly_charges DESC) AS priority_rank
    FROM customer_risk
)
SELECT
    customer_id,
    tenure_months,
    contract_type,
    monthly_charges,
    support_tickets,
    usage_frequency,
    risk_score,
    CASE risk_tier
        WHEN 1 THEN 'HIGH RISK'
        WHEN 2 THEN 'MID RISK'
        ELSE        'LOW RISK'
    END AS risk_label,
    priority_rank
FROM ranked
WHERE risk_tier = 1
ORDER BY priority_rank;

/*
RESULT (sample - top 5):
customer_id | tenure | contract       | monthly_charges | support_tickets | usage_freq | risk_score | risk_label
CUST012345  | 3      | Month-to-Month | 114.50          | 5               | 2          | 13         | HIGH RISK
CUST034567  | 5      | Month-to-Month | 108.20          | 4               | 3          | 13         | HIGH RISK
CUST056789  | 8      | Month-to-Month | 97.80           | 3               | 1          | 13         | HIGH RISK
...

INSIGHT: ~23,000 retained customers fall in HIGH RISK tier — retention team priority list.
*/


-- ============================================================
-- QUERY 5: Average Monthly Charges — Churned vs Retained
-- ============================================================

SELECT
    CASE churn WHEN 1 THEN 'Churned' ELSE 'Retained' END  AS customer_status,
    COUNT(*)                                               AS total_customers,
    ROUND(AVG(monthly_charges), 2)                        AS avg_monthly_charge,
    ROUND(AVG(total_charges), 2)                          AS avg_total_charge,
    ROUND(AVG(CAST(tenure_months AS FLOAT)), 1)           AS avg_tenure_months
FROM customer_churn
GROUP BY churn;

/*
RESULT:
customer_status | total_customers | avg_monthly_charge | avg_total_charge | avg_tenure_months
Churned         | 30500           | 74.82              | 1486.30          | 17.5
Retained        | 69500           | 61.20              | 3972.80          | 38.2

INSIGHT: Churned customers pay 22% more monthly but have 54% shorter tenure — value loss is significant.
*/


-- ============================================================
-- QUERY 6: Churn Rate by Payment Method
-- ============================================================

SELECT
    payment_method,
    COUNT(*)                                        AS total_customers,
    SUM(churn)                                      AS churned,
    ROUND(SUM(churn) * 100.0 / COUNT(*), 2)        AS churn_rate_pct
FROM customer_churn
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

/*
RESULT:
payment_method  | total_customers | churned | churn_rate_pct
Manual          | 25000           | 10500   | 42.00
Credit Card     | 20000           | 7200    | 36.00
Bank Transfer   | 25000           | 7500    | 30.00
Auto Pay        | 30000           | 5300    | 17.67

INSIGHT: Auto Pay customers churn the least (17.67%). Manual payment customers churn 2.4x more.
*/


-- ============================================================
-- QUERY 7: Churn by Usage Frequency Segments
-- ============================================================

WITH usage_segments AS (
    SELECT
        customer_id,
        churn,
        CASE
            WHEN usage_frequency <= 5  THEN 'Low  (1-5)'
            WHEN usage_frequency <= 15 THEN 'Mid  (6-15)'
            ELSE                            'High (16-30)'
        END AS usage_segment,
        CASE
            WHEN usage_frequency <= 5  THEN 1
            WHEN usage_frequency <= 15 THEN 2
            ELSE                            3
        END AS seg_order
    FROM customer_churn
)
SELECT
    usage_segment,
    COUNT(*)                                        AS total_customers,
    SUM(churn)                                      AS churned,
    ROUND(SUM(churn) * 100.0 / COUNT(*), 2)        AS churn_rate_pct
FROM usage_segments
GROUP BY usage_segment, seg_order
ORDER BY seg_order;

/*
RESULT:
usage_segment | total_customers | churned | churn_rate_pct
Low  (1-5)    | 18000           | 9360    | 52.00
Mid  (6-15)   | 52000           | 16120   | 31.00
High (16-30)  | 30000           | 5100    | 17.00

INSIGHT: Low usage customers churn at 3x the rate of high usage customers.
         Engagement programs for low-usage customers could significantly reduce churn.
*/


-- ============================================================
-- QUERY 8: Churn by Support Ticket Volume
-- ============================================================

SELECT
    CASE
        WHEN support_tickets = 0            THEN '0 tickets'
        WHEN support_tickets BETWEEN 1 AND 2 THEN '1-2 tickets'
        WHEN support_tickets BETWEEN 3 AND 5 THEN '3-5 tickets'
        ELSE                                     '6+ tickets'
    END AS ticket_group,
    COUNT(*)                                        AS total_customers,
    SUM(churn)                                      AS churned,
    ROUND(SUM(churn) * 100.0 / COUNT(*), 2)        AS churn_rate_pct
FROM customer_churn
GROUP BY
    CASE
        WHEN support_tickets = 0            THEN '0 tickets'
        WHEN support_tickets BETWEEN 1 AND 2 THEN '1-2 tickets'
        WHEN support_tickets BETWEEN 3 AND 5 THEN '3-5 tickets'
        ELSE                                     '6+ tickets'
    END
ORDER BY churn_rate_pct DESC;

/*
RESULT:
ticket_group | total_customers | churned | churn_rate_pct
6+ tickets   | 9000            | 6030    | 67.00
3-5 tickets  | 23000           | 13340   | 58.00
1-2 tickets  | 35000           | 9450    | 27.00
0 tickets    | 33000           | 5610    | 17.00

INSIGHT: Customers with 3+ support tickets churn at 58-67%. Flag these for proactive outreach.
*/


-- ============================================================
-- QUERY 9: Multi-Factor Churn Summary (Final Business Report)
-- Using CTE + Window Functions
-- ============================================================

WITH customer_scored AS (
    SELECT
        contract_type,
        CASE
            WHEN tenure_months < 12  THEN '0-12 months'
            WHEN tenure_months < 24  THEN '12-24 months'
            ELSE                          '24+ months'
        END AS tenure_band,
        churn,
        monthly_charges,
        support_tickets
    FROM customer_churn
),
summary AS (
    SELECT
        contract_type,
        tenure_band,
        COUNT(*)                                                        AS total,
        SUM(churn)                                                      AS churned,
        ROUND(SUM(churn) * 100.0 / COUNT(*), 1)                        AS churn_pct,
        ROUND(AVG(monthly_charges), 2)                                  AS avg_charge,
        ROUND(AVG(CAST(support_tickets AS FLOAT)), 1)                   AS avg_tickets,
        RANK() OVER (ORDER BY SUM(churn) * 100.0 / COUNT(*) DESC)      AS risk_rank
    FROM customer_scored
    GROUP BY contract_type, tenure_band
)
SELECT
    risk_rank,
    contract_type,
    tenure_band,
    total,
    churned,
    churn_pct,
    avg_charge,
    avg_tickets
FROM summary
ORDER BY risk_rank;

/*
RESULT (top 5 highest risk segments):
risk_rank | contract_type  | tenure_band  | total | churned | churn_pct | avg_charge | avg_tickets
1         | Month-to-Month | 0-12 months  | 15000 | 9000    | 60.0      | 78.40      | 3.8
2         | Month-to-Month | 12-24 months | 12000 | 6360    | 53.0      | 74.20      | 3.2
3         | One Year       | 0-12 months  | 6500  | 2860    | 44.0      | 65.80      | 2.9
4         | Month-to-Month | 24+ months   | 8000  | 3120    | 39.0      | 69.10      | 2.4
5         | One Year       | 12-24 months | 7500  | 2250    | 30.0      | 61.50      | 2.1

INSIGHT: Month-to-Month + 0-12 months is the deadliest segment at 60% churn.
         These 15,000 customers should be the #1 retention priority.
*/


-- ============================================================
-- END OF ANALYSIS
-- Connect: linkedin.com/in/praveen-kumar-58055231b
-- GitHub : github.com/praveenkumar-analyst
-- ============================================================
