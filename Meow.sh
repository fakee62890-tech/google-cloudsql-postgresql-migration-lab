#!/usr/bin/env bash
set -Eeuo pipefail

# Google Cloud Skills Boost lab: migrate stand-alone PostgreSQL to Cloud SQL
# Source VM: postgresql-vm | Destination: postgres86-iv8ej
# This script is intended for the temporary lab project only.

REGION="us-central1"
SOURCE_VM="postgresql-vm"
SOURCE_PROFILE="postgres-vm"
DEST_INSTANCE="postgres86-iv8ej"
DEST_PROFILE="postgres86-iv8ej-destination"
MIGRATION_JOB="vm-to-cloudsql"
SOURCE_USER="import_admin"
SOURCE_PASSWORD='DMS_1s_cool!'

command -v gcloud >/dev/null 2>&1 || { echo "ERROR: Cloud Shell me gcloud command nahi mila." >&2; exit 1; }
PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
[[ -n "$PROJECT_ID" && "$PROJECT_ID" != "(unset)" ]] || { echo "ERROR: Pehle lab project select/authenticate karein." >&2; exit 1; }

# Source VM ka zone aur internal IP automatically detect karo.
SOURCE_ZONE="$(gcloud compute instances list \
  --project="$PROJECT_ID" \
  --filter="name=('$SOURCE_VM')" \
  --format='value(zone.basename())' | head -n1)"
[[ -n "$SOURCE_ZONE" ]] || { echo "ERROR: $SOURCE_VM VM nahi mili." >&2; exit 1; }
SOURCE_IP="$(gcloud compute instances describe "$SOURCE_VM" \
  --project="$PROJECT_ID" --zone="$SOURCE_ZONE" \
  --format='value(networkInterfaces[0].networkIP)')"
[[ -n "$SOURCE_IP" ]] || { echo "ERROR: Source VM ka internal IP nahi mila." >&2; exit 1; }

printf 'Project: %s\nSource: %s (%s, zone %s)\nDestination: %s\n' \
  "$PROJECT_ID" "$SOURCE_VM" "$SOURCE_IP" "$SOURCE_ZONE" "$DEST_INSTANCE"

# Required APIs (already enabled hon to commands harmlessly succeed).
gcloud services enable datamigration.googleapis.com sqladmin.googleapis.com \
  compute.googleapis.com servicenetworking.googleapis.com --project="$PROJECT_ID" --quiet

# Source PostgreSQL connection profile.
if ! gcloud database-migration connection-profiles describe "$SOURCE_PROFILE" \
  --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud database-migration connection-profiles create postgresql "$SOURCE_PROFILE" \
    --project="$PROJECT_ID" --region="$REGION" --role=SOURCE \
    --display-name="PostgreSQL source VM" --host="$SOURCE_IP" --port=5432 \
    --username="$SOURCE_USER" --password="$SOURCE_PASSWORD" --no-async
else
  echo "Source connection profile already exists: $SOURCE_PROFILE"
fi

# Existing Cloud SQL instance ko destination profile ke roop me register karo.
if ! gcloud database-migration connection-profiles describe "$DEST_PROFILE" \
  --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud database-migration connection-profiles create postgresql "$DEST_PROFILE" \
    --project="$PROJECT_ID" --region="$REGION" --role=DESTINATION \
    --cloudsql-instance="$DEST_INSTANCE" --no-async
else
  echo "Destination connection profile already exists: $DEST_PROFILE"
fi

# Continuous migration job using VPC peering with the default VPC.
if ! gcloud database-migration migration-jobs describe "$MIGRATION_JOB" \
  --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud database-migration migration-jobs create "$MIGRATION_JOB" \
    --project="$PROJECT_ID" --region="$REGION" --type=CONTINUOUS \
    --source="$SOURCE_PROFILE" --destination="$DEST_PROFILE" \
    --all-databases \
    --peer-vpc="projects/${PROJECT_ID}/global/networks/default" --no-async
else
  echo "Migration job already exists: $MIGRATION_JOB"
fi

echo "Testing migration job..."
gcloud database-migration migration-jobs verify "$MIGRATION_JOB" \
  --project="$PROJECT_ID" --region="$REGION"

echo "Starting continuous migration job..."
gcloud database-migration migration-jobs start "$MIGRATION_JOB" \
  --project="$PROJECT_ID" --region="$REGION" --no-async

echo "DONE: Continuous migration job start command complete."
gcloud database-migration migration-jobs describe "$MIGRATION_JOB" \
  --project="$PROJECT_ID" --region="$REGION" \
  --format='table(name,state,phase,error.displayMessage)'
