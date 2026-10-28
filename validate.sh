#!/bin/bash
# ==============================================================================
# validate.sh - LUBUNTU Quick Start Validation (GCP)
# ------------------------------------------------------------------------------
# Purpose:
#   - Prints external IP addresses for:
#       - Windows AD admin host (win-ad-*)
#       - Linux domain-joined host (lubuntu-*)
#   - Scoped only to instances attached to VPC: lubuntu-vpc
#
# Requirements:
#   - gcloud CLI installed and authenticated
#   - gcloud project set (gcloud config set project <PROJECT_ID>)
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
WIN_PREFIX="win-ad-"
LINUX_PREFIX="lubuntu-"
VPC_NAME="lubuntu-vpc"

# ------------------------------------------------------------------------------
# Pre-Checks
# ------------------------------------------------------------------------------
if [ -z "${PROJECT_ID}" ]; then
  echo "ERROR: No GCP project set."
  exit 1
fi

# ------------------------------------------------------------------------------
# Lookups (Scoped to VPC)
# ------------------------------------------------------------------------------
windows_ip="$(gcloud compute instances list \
  --filter="name~'^${WIN_PREFIX}.*' AND networkInterfaces.network:${VPC_NAME}" \
  --format="value(networkInterfaces[0].accessConfigs[0].natIP)" \
  --limit=1 2>/dev/null)"

linux_ip="$(gcloud compute instances list \
  --filter="name~'^${LINUX_PREFIX}.*' AND networkInterfaces.network:${VPC_NAME}" \
  --format="value(networkInterfaces[0].accessConfigs[0].natIP)" \
  --limit=1 2>/dev/null)"

# ------------------------------------------------------------------------------
# Quick Start Output
# ------------------------------------------------------------------------------
echo ""
echo "============================================================================"
echo "LUBUNTU Quick Start - Validation Output (GCP)"
echo "============================================================================"
echo ""

printf "%-28s %s\n" "NOTE: Windows RDP Host:" "${windows_ip:-<not found>}"
printf "%-28s %s\n" "NOTE: Lubuntu Host:" "${linux_ip:-<not found>}"

echo ""
# ------------------------------------------------------------------------------
# Sign-in
# ------------------------------------------------------------------------------
# jsmith is in mcloud-users and linux-admins (sudo on the desktop).
jsmith_password="$(gcloud secrets versions access latest \
  --secret="jsmith-ad-credentials-lubuntu" 2>/dev/null | jq -r .password 2>/dev/null || true)"

if [ -z "${jsmith_password}" ]; then
  printf "%-28s %s\n" "ERROR: Sign in:" "Not found (secret jsmith-ad-credentials-lubuntu)"
else
  printf "%-28s %s\n" "NOTE: Sign in:" "jsmith / ${jsmith_password}"
fi
printf "%-28s %s\n" "" "Desktop: jsmith. Windows: MCLOUD\\jsmith."
printf "%-28s %s\n" "" "Other users: <user>-ad-credentials-lubuntu"
printf "%-28s %s\n" "" "in Secret Manager."
echo ""
