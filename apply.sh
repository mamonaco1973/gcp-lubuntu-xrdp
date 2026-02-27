#!/bin/bash
# ================================================================================
# apply.sh
# --------------------------------------------------------------------------------
# Purpose:
#   01) Terraform: provision directory services (Mini-AD)
#   02) Packer:    build GCP Lubuntu image
#   03) Terraform: deploy servers joined to directory
#   04) Validate:  run post-build checks
#
# Assumptions:
#   - ./credentials.json exists (service account key)
#   - check_env.sh validates tools and environment
# ================================================================================

set -e

# ------------------------------------------------------------------------------
# Pre-flight: Validate environment
# ------------------------------------------------------------------------------

# Run environment checks (tools, env vars, config)
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# ------------------------------------------------------------------------------
# Phase 1: Directory Services (Terraform)
# ------------------------------------------------------------------------------

# Provision Active Directory / directory services
cd 01-directory

# Initialize Terraform (providers, backend)
terraform init

# Apply configuration (no prompt)
terraform apply -auto-approve
if [ $? -ne 0 ]; then
  echo "ERROR: Terraform apply failed in 01-directory. Exiting."
  exit 1
fi

# Return to repo root
cd ..

# ------------------------------------------------------------------------------
# Phase 2: Build GCP Lubuntu Image (Packer)
# ------------------------------------------------------------------------------

# Extract GCP project_id from service account key
project_id=$(jq -r '.project_id' "./credentials.json")

# Authenticate gcloud with service account key
# Export GOOGLE_APPLICATION_CREDENTIALS for ADC-compatible tools
gcloud auth activate-service-account --key-file="./credentials.json" \
  > /dev/null 2> /dev/null
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/credentials.json"

# Build Lubuntu image with Packer
cd 02-packer
packer init .

packer build \
  -var="project_id=$project_id" \
  lubuntu_image.pkr.hcl

# Return to repo root
cd ..

# ------------------------------------------------------------------------------
# Phase 3: Server Deployment (Terraform)
# ------------------------------------------------------------------------------

# Determine latest Lubuntu image in family lubuntu-images
lubuntu_image=$(gcloud compute images list \
  --filter="name~'^lubuntu-image' AND family=lubuntu-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")

if [[ -z "$lubuntu_image" ]]; then
  echo "ERROR: No latest lubuntu-image found in family lubuntu-images."
  exit 1
fi

echo "NOTE: Lubuntu image is $lubuntu_image"

# Deploy VMs that join the directory
cd 03-servers

# Initialize Terraform
terraform init

# Apply configuration (no prompt)
terraform apply \
  -var="lubuntu_image_name=$lubuntu_image" \
  -auto-approve

# Return to repo root
cd ..

# ------------------------------------------------------------------------------
# Post-build: Validate
# ------------------------------------------------------------------------------

# Run validation checks
./validate.sh