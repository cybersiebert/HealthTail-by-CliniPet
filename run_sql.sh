#!/usr/bin/env bash
# Run the HealthTail SQL pipeline using BigQuery.
# Usage: ./run_sql.sh [--project PROJECT_ID] [SQL_FILE]

set -euo pipefail

PROJECT=""
SQL_FILE="healthtail.sql"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT="$2"
      shift 2
      ;;
    *)
      SQL_FILE="$1"
      shift
      ;;
  esac
 done

if [[ -n "$PROJECT" ]]; then
  bq query --use_legacy_sql=false --project_id="$PROJECT" < "$SQL_FILE"
else
  bq query --use_legacy_sql=false < "$SQL_FILE"
fi

