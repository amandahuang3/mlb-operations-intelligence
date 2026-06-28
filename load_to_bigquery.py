import pandas as pd
from google.cloud import bigquery
import os

# ── UPDATE THESE TWO LINES ──────────────────────────────────────────
PROJECT_ID = "project-3ab1bdb7-97b6-4d9c-af7"   # your GCP project ID
DATA_FOLDER = r"C:\Users\amand\Documents\OwnProject\mlbA\lahman"  # folder where your CSVs are
# ────────────────────────────────────────────────────────────────────

DATASET_ID = "raw"

FILES = {
    "people":      "People.csv",
    "teams":       "Teams.csv",
    "batting":     "Batting.csv",
    "pitching":    "Pitching.csv",
    "fielding":    "Fielding.csv",
    "salaries":    "Salaries.csv",
    "series_post": "SeriesPost.csv",
}

client = bigquery.Client(project=PROJECT_ID)

# Create dataset if it doesn't exist
dataset_ref = bigquery.Dataset(f"{PROJECT_ID}.{DATASET_ID}")
dataset_ref.location = "US"
try:
    client.create_dataset(dataset_ref)
    print(f"Created dataset: {DATASET_ID}")
except Exception:
    print(f"Dataset {DATASET_ID} already exists — skipping create")

# Upload each file
job_config = bigquery.LoadJobConfig(
    autodetect=True,
    skip_leading_rows=1,
    source_format=bigquery.SourceFormat.CSV,
    write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
)

for table_name, filename in FILES.items():
    filepath = os.path.join(DATA_FOLDER, filename)
    
    if not os.path.exists(filepath):
        print(f"  MISSING: {filepath} — skipping")
        continue

    print(f"Uploading {filename} → raw.{table_name} ...", end=" ")
    
    with open(filepath, "rb") as f:
        job = client.load_table_from_file(
            f,
            f"{PROJECT_ID}.{DATASET_ID}.{table_name}",
            job_config=job_config,
        )
    job.result()  # wait for completion
    
    table = client.get_table(f"{PROJECT_ID}.{DATASET_ID}.{table_name}")
    print(f"Done — {table.num_rows:,} rows")

print("\nAll tables loaded. Verify in BigQuery console.")