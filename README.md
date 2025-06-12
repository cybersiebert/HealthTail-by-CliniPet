# HealthTail Medication Flow – Stock In & Stock Out Analytics
## Monthly Medication Inventory Insights

================================================================================
    Step 1 – Data Cleaning & Aggregation for HealthTail Project (Clinipet)
--------------------------------------------------------------------------------
    Author:     Matthias Siebert
    Project:    clinipet-462608.healthtail_integration
    Date:       2025-06-11
--------------------------------------------------------------------------------
    Description:
    1. Creates a cleaned table 'registration_clean' from the patient registration
       cards (healthtail_reg_cards):
        - Converts patient names to uppercase
        - Cleans the phone numbers to keep digits only
        - Replaces missing values in 'breed' with 'Unknown'
    2. Creates the aggregated table 'med_audit' to summarize monthly
       medication stock movement:
        - Aggregates purchased medications ("stock in")
        - Aggregates medications dispensed during visits ("stock out")
    Both tables are saved in the dataset 'clinipet-462608.healthtail_integration'
    and serve as the foundation for further analysis and the Looker Studio dashboard.
================================================================================


-- 1. DATA CLEANING: Create registration_clean table in the target dataset
CREATE OR REPLACE TABLE clinipet-462608.healthtail_integration.registration_clean AS
SELECT
  patient_id,
  owner_id,
  UPPER(patient_name) AS patient_name,
  pet_type,
  COALESCE(NULLIF(breed, ''), 'Unknown') AS breed,
  gender,
  patient_age,
  date_registration,
  REGEXP_REPLACE(owner_phone, r'\D', '') AS owner_phone,
  owner_name
FROM clinipet-462608.healthtail_integration.healthtail_reg_cards;

-- 2. AGGREGATED TABLE: Create med_audit table in the target dataset
CREATE OR REPLACE TABLE clinipet-462608.healthtail_integration.med_audit AS
WITH stock_in AS (
  SELECT
    DATE_TRUNC(month_invoice, MONTH) AS month,
    med_name,
    SUM(packs) AS total_packs,
    SUM(total_price) AS total_value,
    'stock in' AS stock_movement
  FROM clinipet-462608.healthtail_integration.invoices
  GROUP BY month, med_name
),
stock_out AS (
  SELECT
    DATE_TRUNC(visit_datetime, MONTH) AS month,
    med_prescribed AS med_name,
    SUM(med_dosage) AS total_packs,
    SUM(med_cost) AS total_value,
    'stock out' AS stock_movement
  FROM clinipet-462608.healthtail_integration.visits
  GROUP BY month, med_name
)
SELECT * FROM stock_in
UNION ALL
SELECT * FROM stock_out;



================================================================================
    Step 2 – Research Questions: Medication Audit (HealthTail)
--------------------------------------------------------------------------------
    Author:     Matthias Siebert
    Project:    clinipet-462608.healthtail_consumer
    Date:       2025-06-11
--------------------------------------------------------------------------------
    Instructions:
    Each research question is implemented as a VIEW in
    'clinipet-462608.healthtail_consumer' so it can be queried at any time.
================================================================================


-- 1. Medication with the highest total spending
CREATE OR REPLACE VIEW clinipet-462608.healthtail_consumer.q1_top_total_spent_med AS
SELECT
    med_name,
    SUM(total_value) AS total_spent
FROM clinipet-462608.healthtail_integration.med_audit
WHERE stock_movement = 'stock out'
GROUP BY med_name
ORDER BY total_spent DESC
LIMIT 1;

-- 2. Medication with the highest single monthly spending, and the month
CREATE OR REPLACE VIEW clinipet-462608.healthtail_consumer.q2_top_monthly_spent_med AS
SELECT
    med_name,
    month,
    total_value
FROM clinipet-462608.healthtail_integration.med_audit
WHERE stock_movement = 'stock out'
ORDER BY total_value DESC
LIMIT 1;

-- 3. Month with the highest number of medication packs spent
CREATE OR REPLACE VIEW clinipet-462608.healthtail_consumer.q3_top_packs_spent_month AS
SELECT
    month,
    SUM(total_packs) AS packs_spent
FROM clinipet-462608.healthtail_integration.med_audit
WHERE stock_movement = 'stock out'
GROUP BY month
ORDER BY packs_spent DESC
LIMIT 1;

-- 4. Average monthly packs spent for the top revenue-generating medication
CREATE OR REPLACE VIEW clinipet-462608.healthtail_consumer.q4_avg_monthly_packs_top_revenue_med AS
WITH top_revenue_med AS (
  SELECT med_name
  FROM clinipet-462608.healthtail_integration.med_audit
  WHERE stock_movement = 'stock out'
  GROUP BY med_name
  ORDER BY SUM(total_value) DESC
  LIMIT 1
)
SELECT
    m.med_name,
    AVG(m.total_packs) AS avg_monthly_packs_spent
FROM clinipet-462608.healthtail_integration.med_audit m
JOIN top_revenue_med t
  ON m.med_name = t.med_name
WHERE m.stock_movement = 'stock out'
GROUP BY m.med_name;


HealthTail Medication Flow – Stock In & Stock Out AnalyticsMonthly Medication Inventory InsightsThis repository contains the SQL scripts for cleaning, aggregating, and analyzing medication inventory data for the HealthTail project. The process is divided into two main steps: data preparation and analytical queries.Step 1 – Data Cleaning & Aggregation for HealthTail Project (Clinipet)This script prepares the raw data for analysis by cleaning patient registration information and aggregating monthly medication stock movements.Author: Matthias SiebertProject: clinipet-462608.healthtail_integrationDate: 2025-06-11Description:Creates a cleaned table registration_clean from the patient registration cards (healthtail_reg_cards):Converts patient names to uppercase.Cleans phone numbers to keep only digits.Replaces missing values in breed with 'Unknown'.Creates the aggregated table med_audit to summarize monthly medication stock movement:Aggregates purchased medications ("stock in").Aggregates medications dispensed during visits ("stock out").Both tables are saved in the dataset clinipet-462608.healthtail_integration and serve as the foundation for further analysis and a Looker Studio dashboard.SQL Script:-- ================================================================================
--     Step 1 – Data Cleaning & Aggregation for HealthTail Project (Clinipet)
-- --------------------------------------------------------------------------------
--     Author:       Matthias Siebert
--     Project:      clinipet-462608.healthtail_integration
--     Date:         2025-06-11
-- ================================================================================

-- 1. DATA CLEANING: Create registration_clean table in the target dataset
CREATE OR REPLACE TABLE clinipet-462608.healthtail_integration.registration_clean AS
SELECT
  patient_id,
  owner_id,
  UPPER(patient_name) AS patient_name,
  pet_type,
  COALESCE(NULLIF(breed, ''), 'Unknown') AS breed,
  gender,
  patient_age,
  date_registration,
  REGEXP_REPLACE(owner_phone, r'\D', '') AS owner_phone,
  owner_name
FROM clinipet-462608.healthtail_integration.healthtail_reg_cards;

-- 2. AGGREGATED TABLE: Create med_audit table in the target dataset
CREATE OR REPLACE TABLE clinipet-462608.healthtail_integration.med_audit AS
WITH stock_in AS (
  SELECT
    DATE_TRUNC(month_invoice, MONTH) AS month,
    med_name,
    SUM(packs) AS total_packs,
    SUM(total_price) AS total_value,
    'stock in' AS stock_movement
  FROM clinipet-462608.healthtail_integration.invoices
  GROUP BY month, med_name
),
stock_out AS (
  SELECT
    DATE_TRUNC(visit_datetime, MONTH) AS month,
    med_prescribed AS med_name,
    SUM(med_dosage) AS total_packs,
    SUM(med_cost) AS total_value,
    'stock out' AS stock_movement
  FROM clinipet-462608.healthtail_integration.visits
  GROUP BY month, med_name
)
SELECT * FROM stock_in
UNION ALL
SELECT * FROM stock_out;
Step 2 – Research Questions: Medication Audit (HealthTail)This script creates several SQL VIEWs to answer specific business questions about medication usage and spending.Author: Matthias SiebertProject: clinipet-462608.healthtail_consumerDate: 2025-06-11Instructions:Each research question is implemented as a VIEW in clinipet-462608.healthtail_consumer so it can be queried at any time.Analytical Queries:1. Medication with the highest total spendingCREATE OR REPLACE VIEW clinipet-462608.healthtail_consumer.q1_top_total_spent_med AS
SELECT
    med_name,
    SUM(total_value) AS total_spent
FROM clinipet-462608.healthtail_integration.med_audit
WHERE stock_movement = 'stock out'
GROUP BY med_name
ORDER BY total_spent DESC
LIMIT 1;
2. Medication with the highest single monthly spending, and the monthCREATE OR REPLACE VIEW clinipet-462608.healthtail_consumer.q2_top_monthly_spent_med AS
SELECT
    med_name,
    month,
    total_value
FROM clinipet-462608.healthtail_integration.med_audit
WHERE stock_movement = 'stock out'
ORDER BY total_value DESC
LIMIT 1;
3. Month with the highest number of medication packs spentCREATE OR REPLACE VIEW clinipet-462608.healthtail_consumer.q3_top_packs_spent_month AS
SELECT
    month,
    SUM(total_packs) AS packs_spent
FROM clinipet-462608.healthtail_integration.med_audit
WHERE stock_movement = 'stock out'
GROUP BY month
ORDER BY packs_spent DESC
LIMIT 1;
4. Average monthly packs spent for the top revenue-generating medicationCREATE OR REPLACE VIEW clinipet-462608.healthtail_consumer.q4_avg_monthly_packs_top_revenue_med AS
WITH top_revenue_med AS (
  SELECT med_name
  FROM clinipet-462608.healthtail_integration.med_audit
  WHERE stock_movement = 'stock out'
  GROUP BY med_name
  ORDER BY SUM(total_value) DESC
  LIMIT 1
)
SELECT
    m.med_name,
    AVG(m.total_packs) AS avg_monthly_packs_spent
FROM clinipet-462608.healthtail_integration.med_audit m
JOIN top_revenue_med t
  ON m.med_name = t.med_name
WHERE m.stock_movement = 'stock out'
GROUP BY m.med_name;
