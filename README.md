# HealthTail Medication Flow

This project contains SQL routines for analyzing medication inventory at Clinipet. The workflow cleans registration records, aggregates medication purchases and usage, and provides views that answer common audit questions.

## Files

- `scripts/medication_flow.sql` – BigQuery SQL statements for building the data tables and views.

## Usage

Run the commands in the SQL file in your BigQuery environment. For reference, the script begins with:

```sql
/*
# HealthTail Medication Flow – Stock In & Stock Out Analytics
## Monthly Medication Inventory Insights
*/
```

The rest of the script sets up the cleaned registration table, the `med_audit` aggregation table, and several analytical views.
