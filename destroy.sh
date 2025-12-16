#!/bin/bash
# ==============================================================================
# destroy.sh
# ------------------------------------------------------------------------------
# Purpose:
#   - Tear down the GCP Xubuntu environment:
#       01) Destroy servers (Terraform) using the latest Xubuntu image name
#       02) Delete all Xubuntu images from the project (best-effort)
#       03) Destroy directory services (Terraform)
#
# Notes:
#   - Uses the most recently created image in family 'xubuntu-images' whose name
#     matches '^xubuntu-image' as an input to 03-servers Terraform destroy.
#   - Image deletion is best-effort and continues on failures.
# ==============================================================================

#!/bin/bash

# ------------------------------------------------------------------------------
# Determine Latest Xubuntu Image
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# Phase 1: Destroy Servers (Terraform)
# ------------------------------------------------------------------------------

cd 03-servers

terraform init
terraform destroy \
  -var="xubuntu_image_name=$xubuntu_image" \
  -auto-approve

cd ..

# ------------------------------------------------------------------------------
# Phase 2: Delete Xubuntu Images (Best-Effort)
# ------------------------------------------------------------------------------

image_list=$(gcloud compute images list \
  --format="value(name)" \
  --filter="name~'^(xubuntu)'")     # Regex match for names starting with 'xubuntu'

# Check if any were found
if [ -z "$image_list" ]; then
  echo "NOTE: No images found starting with 'xubuntu'. Continuing..."
else
  echo "NOTE: Deleting images..."
  for image in $image_list; do
    echo "NOTE: Deleting image: $image"
    gcloud compute images delete "$image" --quiet || echo "WARNING: Failed to delete image: $image"  # Continue even if deletion fails
  done
fi

# ------------------------------------------------------------------------------
# Phase 3: Destroy Directory Services (Terraform)
# ------------------------------------------------------------------------------

cd 01-directory

terraform init
terraform destroy -auto-approve

cd ..
