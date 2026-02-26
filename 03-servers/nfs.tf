# ================================================================================
# Google Cloud Filestore (Basic NFS Server) with Firewall
# --------------------------------------------------------------------------------
# Provisions Filestore instance for NFS storage with firewall access.
#
# Key Points:
#   - Fully managed NFS storage in GCP
#   - Minimum size 1024 GiB (1 TB)
#   - Deployed in specific zone, not region-wide
#   - Basic tiers support NFSv3 only
#   - NFS uses port 2049 (TCP and UDP)
#   - Source 0.0.0.0/0 is lab-only; restrict in production
# ================================================================================
resource "google_filestore_instance" "nfs_server" {

  # ------------------------------------------------------------------------------
  # Filestore Configuration
  # ------------------------------------------------------------------------------
  #   - Name unique within project
  #   - Tier controls performance and pricing
  #   - Location must be zonal (e.g., us-central1-b)
  #   - Project ID pulled from local credentials
  name     = "lubuntu-nfs-server"
  tier     = "BASIC_HDD"     # Basic HDD tier
  location = "us-central1-b" # Zonal deployment
  project  = local.credentials.project_id

  # ------------------------------------------------------------------------------
  # File Share Configuration
  # ------------------------------------------------------------------------------
  #   - Minimum Basic capacity 1024 GiB
  #   - Export options define access and IP ranges
  file_shares {
    capacity_gb = 1024 # 1 TB minimum
    name        = "filestore"

    nfs_export_options {
      access_mode = "READ_WRITE"     # Allow read/write
      squash_mode = "NO_ROOT_SQUASH" # Preserve root privileges
      ip_ranges   = ["0.0.0.0/0"]    # Lab only; restrict in production
    }
  }

  # ------------------------------------------------------------------------------
  # Network Configuration
  # ------------------------------------------------------------------------------
  #   - Attach to specified VPC network
  #   - IPv4 only mode
  networks {
    network = data.google_compute_network.ad_vpc.name
    modes   = ["MODE_IPV4"]
  }
}

# ================================================================================
# Firewall Rule: Allow NFS Traffic
# --------------------------------------------------------------------------------
# Allow NFS port 2049 over TCP and UDP.
#
# Key Points:
#   - Required for Linux clients mounting Filestore
#   - Source 0.0.0.0/0 is lab-only
#   - Restrict to specific subnets in production
# ================================================================================
resource "google_compute_firewall" "allow_nfs" {
  name    = "lubuntu-allow-nfs"
  network = data.google_compute_network.ad_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["2049"]
  }

  allow {
    protocol = "udp"
    ports    = ["2049"]
  }

  source_ranges = ["0.0.0.0/0"] # Lab only; restrict in production
}

# ================================================================================
# Output: Filestore IP Address
# --------------------------------------------------------------------------------
# Expose private IP for mount commands.
# Example mount: <IP_ADDRESS>:/filestore
# ================================================================================
# output "filestore_ip" {
#   value = google_filestore_instance.nfs_server.networks[0].ip_addresses[0]
# }