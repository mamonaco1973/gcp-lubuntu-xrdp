# ================================================================================
# Custom VPC, Subnet, Router, and NAT for AD Environment
# --------------------------------------------------------------------------------
# Provisions:
#   01) Custom-mode VPC (no default subnets)
#   02) Explicit subnet for AD resources
#   03) Cloud Router for dynamic routing
#   04) Cloud NAT for outbound internet without public IPs
#
# Key Points:
#   - Custom VPC avoids auto-created subnets
#   - Subnet in us-central1 with CIDR 10.1.0.0/24
#   - Cloud Router enables NAT and advanced networking
#   - Cloud NAT provides secure outbound for private VMs
# ================================================================================

# ================================================================================
# VPC Network: Active Directory VPC
# --------------------------------------------------------------------------------
# Creates custom-mode VPC named ad-vpc.
#
# Key Points:
#   - Auto subnet creation disabled
#   - All subnets must be manually defined
# ================================================================================
resource "google_compute_network" "ad_vpc" {
  name                    = var.vpc
  auto_create_subnetworks = false
}

# ================================================================================
# Subnet: Active Directory Subnet
# --------------------------------------------------------------------------------
# Defines subnet inside ad-vpc for AD resources.
#
# Key Points:
#   - Region: us-central1
#   - CIDR: 10.1.0.0/24
#   - Explicitly tied to VPC above
# ================================================================================
resource "google_compute_subnetwork" "ad_subnet" {
  name          = var.subnet
  region        = "us-central1"
  network       = google_compute_network.ad_vpc.id
  ip_cidr_range = "10.1.0.0/24"
}

# ================================================================================
# Cloud Router
# --------------------------------------------------------------------------------
# Creates Cloud Router in AD VPC.
#
# Key Points:
#   - Required for Cloud NAT
#   - Supports dynamic routes and BGP
# ================================================================================
resource "google_compute_router" "ad_router" {
  name    = "lubuntu-ad-router"
  network = google_compute_network.ad_vpc.id
  region  = "us-central1"
}

# ================================================================================
# Cloud NAT
# --------------------------------------------------------------------------------
# Provides outbound internet for private AD subnet resources.
#
# Key Points:
#   - No public IPs required on instances
#   - NAT IPs allocated automatically
#   - Logs all flows (ALL)
# ================================================================================
resource "google_compute_router_nat" "ad_nat" {
  name   = "lubuntu-ad-nat"
  router = google_compute_router.ad_router.name
  region = google_compute_router.ad_router.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ALL"
  }
}