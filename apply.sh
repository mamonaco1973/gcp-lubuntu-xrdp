#!/bin/bash
# ==============================================================================
# apply.sh
# ------------------------------------------------------------------------------
# Purpose:
#   - End-to-end build for the GCP Xubuntu environment:
#       01) Terraform: provision directory services (Mini-AD)
#       02) Packer:    build the GCP Xubuntu image
#       03) Terraform: provision servers joined to the directory
#       04) Validate:  run post-build checks
#
# Assumptions:
#   - ./credentials.json exists in the repo root (service account key)
#   - check_env.sh validates required tools and environment pre-reqs
# ==============================================================================

set -e

# ------------------------------------------------------------------------------
# Pre-flight: Validate environment
# ------------------------------------------------------------------------------

# Run environment checks (tools, env vars, config). Exit on failure.
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# ------------------------------------------------------------------------------
# Phase 1: Directory Services (Terraform)
# ------------------------------------------------------------------------------

# Build Active Directory / directory services.
cd 01-directory

# Initialize Terraform (providers, backend, etc.).
terraform init

# Apply the configuration (no prompt).
terraform apply -auto-approve
if [ $? -ne 0 ]; then
  echo "ERROR: Terraform apply failed in 01-directory. Exiting."
  exit 1
fi

# Return to repo root.
cd ..

# ------------------------------------------------------------------------------
# Phase 2: Build GCP Xubuntu Image (Packer)
# ------------------------------------------------------------------------------

# Extract the GCP project_id from the service account key.
project_id=$(jq -r '.project_id' "./credentials.json")

# Authenticate gcloud using the local service account key.
# Also export GOOGLE_APPLICATION_CREDENTIALS for tools that use ADC.
gcloud auth activate-service-account --key-file="./credentials.json" > /dev/null 2> /dev/null
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/credentials.json"

# Run Packer to build the Xubuntu image in GCP.
cd 02-packer
packer init .

packer build \
  -var="project_id=$project_id" \
  xubuntu_image.pkr.hcl

# Return to repo root.
cd ..

# ------------------------------------------------------------------------------
# Phase 3: Server Deployment (Terraform)
# ------------------------------------------------------------------------------

# Determine Latest Xubuntu Image

xubuntu_image=$(gcloud compute images list \
  --filter="name~'^xubuntu-image' AND family=xubuntu-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")  # Grabs most recently created image from 'xubuntu-images' family

if [[ -z "$xubuntu_image" ]]; then
  echo "ERROR: No latest image found for 'xubuntu-image' in family 'xubuntu-images'."
  exit 1  # Hard fail if no image found — we can't safely destroy without this input
fi

echo "NOTE: Xubuntu image is $xubuntu_image"

# Build VMs that connect to / join the directory.
cd 03-servers

# Initialize Terraform (providers, backend, etc.).
terraform init

# Apply the configuration (no prompt).
terraform apply \
  -var="xubuntu_image_name=$xubuntu_image" \
  -auto-approve

# Return to repo root.
cd ..

# ------------------------------------------------------------------------------
# Post-build: Validate
# ------------------------------------------------------------------------------

# Run validation checks after provisioning completes.
./validate.sh
