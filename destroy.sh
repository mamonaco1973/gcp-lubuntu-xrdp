#!/bin/bash
# ==============================================================================
# destroy.sh
# ------------------------------------------------------------------------------
# Purpose:
#   - Tear down the GCP Lubuntu environment:
#       01) Destroy servers (Terraform) using the latest Lubuntu image name
#       02) Delete all Lubuntu images from the project (best-effort)
#       03) Destroy directory services (Terraform)
#
# Notes:
#   - Uses the most recently created image in family 'lubuntu-images' whose name
#     matches '^lubuntu-image' as an input to 03-servers Terraform destroy.
#   - Image deletion is best-effort and continues on failures.
# ==============================================================================

#!/bin/bash

# ------------------------------------------------------------------------------
# Determine Latest Lubuntu Image
# ------------------------------------------------------------------------------

lubuntu_image=$(gcloud compute images list \
  --filter="name~'^lubuntu-image' AND family=lubuntu-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")  # Grabs most recently created image from 'lubuntu-images' family

if [[ -z "$lubuntu_image" ]]; then
  echo "ERROR: No latest image found for 'lubuntu-image' in family 'lubuntu-images'."
  exit 1  # Hard fail if no image found — we can't safely destroy without this input
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

image_list=$(gcloud compute images list \
  --format="value(name)" \
  --filter="name~'^(lubuntu)'")     # Regex match for names starting with 'lubuntu'

# Check if any were found
if [ -z "$image_list" ]; then
  echo "NOTE: No images found starting with 'lubuntu'. Continuing..."
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
