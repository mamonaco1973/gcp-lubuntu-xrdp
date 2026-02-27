#!/bin/bash
# ================================================================================
# destroy.sh
# --------------------------------------------------------------------------------
# Purpose:
#   01) Destroy servers using latest Lubuntu image
#   02) Delete Lubuntu images (best-effort)
#   03) Destroy directory services
#
# Notes:
#   - Uses newest image in family lubuntu-images
#   - Image deletion continues on failure
# ================================================================================

# ------------------------------------------------------------------------------
# Determine Latest Lubuntu Image
# ------------------------------------------------------------------------------

# Query newest image in family lubuntu-images
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

# ------------------------------------------------------------------------------
# Phase 1: Destroy Servers (Terraform)
# ------------------------------------------------------------------------------

cd 03-servers

terraform init
terraform destroy \
  -var="lubuntu_image_name=$lubuntu_image" \
  -auto-approve

cd ..

# ------------------------------------------------------------------------------
# Phase 2: Delete Lubuntu Images (Best-Effort)
# ------------------------------------------------------------------------------

# List images with names starting with lubuntu
image_list=$(gcloud compute images list \
  --format="value(name)" \
  --filter="name~'^(lubuntu)'")

if [ -z "$image_list" ]; then
  echo "NOTE: No images found starting with lubuntu. Continuing..."
else
  echo "NOTE: Deleting images..."
  for image in $image_list; do
    echo "NOTE: Deleting image: $image"
    gcloud compute images delete "$image" --quiet \
      || echo "WARNING: Failed to delete image: $image"
  done
fi

# ------------------------------------------------------------------------------
# Phase 3: Destroy Directory Services (Terraform)
# ------------------------------------------------------------------------------

cd 01-directory

terraform init
terraform destroy -auto-approve

cd ..