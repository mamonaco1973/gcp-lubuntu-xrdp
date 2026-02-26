# ================================================================================
# Google Cloud Provider Configuration
# --------------------------------------------------------------------------------
# Configures Google provider for Terraform.
#
# Key Points:
#   - Uses service account JSON at ../credentials.json
#   - Project ID and email extracted from decoded JSON
# ================================================================================
provider "google" {
  project     = local.credentials.project_id # Project ID from decoded JSON
  credentials = file("../credentials.json")  # Path to service account JSON
}

# ================================================================================
# Local Variables
# --------------------------------------------------------------------------------
# Decode credentials for reuse across modules.
#
# Key Points:
#   - credentials stores full JSON as map
#   - service_account_email references service account identity
# ================================================================================
locals {
  credentials           = jsondecode(file("../credentials.json"))
  service_account_email = local.credentials.client_email
}