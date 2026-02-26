# ================================================================================
# Google Cloud Provider & Local Variables
# --------------------------------------------------------------------------------
# Configure Google provider using service account JSON.
#
# Key Points:
#   - Provider uses project ID and credentials for auth
#   - Locals decode JSON for project_id and service account email
# ================================================================================
provider "google" {
  project     = local.credentials.project_id # Project ID from credentials.json
  credentials = file("../credentials.json")  # Path to service account JSON
}

# ================================================================================
# Local Variables
# --------------------------------------------------------------------------------
# Decode credentials JSON and extract useful fields.
#
# Key Points:
#   - credentials contains full decoded JSON map
#   - service_account_email used for IAM bindings
# ================================================================================
locals {
  credentials           = jsondecode(file("../credentials.json"))
  service_account_email = local.credentials.client_email
}

# ================================================================================
# Data Sources: Network and Subnet
# --------------------------------------------------------------------------------
# Lookup existing VPC and subnet for resource attachment.
#
# Key Points:
#   - ad-vpc is base VPC for AD lab resources
#   - ad-subnet located in us-central1
# ================================================================================
data "google_compute_network" "ad_vpc" {
  name = var.vpc
}

data "google_compute_subnetwork" "ad_subnet" {
  name   = var.subnet
  region = "us-central1"
}

# ================================================================================
# INPUT VARIABLE: Lubuntu Image Name
# --------------------------------------------------------------------------------
# Name of Packer-built Lubuntu image used for VM boot disk.
# ================================================================================
variable "lubuntu_image_name" {
  description = "Name of the Packer-built Lubuntu GCP image"
  type        = string
}

# ================================================================================
# DATA SOURCE: GCE IMAGE LOOKUP
# --------------------------------------------------------------------------------
# Resolve custom Lubuntu image by name in current project.
# Enables safe reference via self_link or id.
# ================================================================================
data "google_compute_image" "lubuntu_packer_image" {
  name    = var.lubuntu_image_name       # Image name from workflow
  project = local.credentials.project_id # GCP project containing image
}