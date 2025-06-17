/*
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
    1. Creates a cleaned table 'registration_clean_with visits' from the patient registration
       cards (healthtail_reg_cards):
        - Converts patient names to uppercase
        - Cleans the phone numbers to keep digits only
        - Replaces missing values in 'breed' with 'Unknown'
        - Left Join with visits
    2. Creates the aggregated table 'med_audit' to summarize monthly
       medication stock movement:
        - Aggregates purchased medications ("stock in")
        - Aggregates medications dispensed during visits ("stock out")
    Both tables are saved in the dataset 'clinipet-462608.healthtail_integration'
    and serve as the foundation for further analysis and the Looker Studio dashboard.
================================================================================
*/

-- Step 1: Create a cleaned registration table, joining with visits for richer analysis
CREATE OR REPLACE TABLE clinipet-462608.healthtail_integration.registration_clean_with_visits AS
SELECT
  reg.patient_id,
  reg.owner_id,
  UPPER(reg.patient_name) AS patient_name,
  reg.pet_type,
  COALESCE(NULLIF(reg.breed, ''), 'Unknown') AS breed,
  reg.gender,
  reg.patient_age,
  reg.date_registration,
  REGEXP_REPLACE(reg.owner_phone, r'\D', '') AS owner_phone,
  reg.owner_name,
  v.visit_id,
  v.visit_datetime,
  v.diagnosis,
  v.doctor,
  v.med_prescribed,
  v.med_cost,
  v.med_dosage
FROM
  clinipet-462608.healthtail_stage.healthtail_reg_cards reg
LEFT JOIN
  clinipet-462608.healthtail_stage.visits v
ON
  reg.patient_id = v.patient_id;

-- This table combines cleaned registration data with visit-level info for all relevant analyses.

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


/*
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
*/

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


## License

This project is licensed under the [MIT License](LICENSE).

