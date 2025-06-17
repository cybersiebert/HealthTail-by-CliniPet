# Running the HealthTail SQL Script

This repository contains a BigQuery SQL script (`healthtail.sql`) that creates the necessary tables and views for the HealthTail analytics pipeline.

## Required Environment

1. **Google Cloud project** with BigQuery enabled.
2. **Google Cloud SDK** installed locally for access to the `bq` command-line tool.
   - Install from <https://cloud.google.com/sdk/docs/install>.
3. Authenticate with your Google Cloud account and set the desired project:
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

## Steps to Execute

1. Clone this repository and navigate to its directory.
2. Ensure the `bq` CLI is available by running `bq version`.
3. Execute the SQL script using the provided helper script:
   ```bash
   ./run_sql.sh --project YOUR_PROJECT_ID
   ```
   - If `YOUR_PROJECT_ID` is already set in gcloud, you may omit the `--project` option.
   - The script defaults to running `healthtail.sql`, but you can pass a different path as an argument.

The script will create the cleaned registration table, aggregate medication stock movement, and build views for the analytical queries in BigQuery.

