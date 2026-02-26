# ================================================================================
# Random String, Firewall, and Lubuntu VM for AD/NFS Gateway
# --------------------------------------------------------------------------------
# Provisions:
#   01) Random suffix for unique resource names
#   02) Firewall rules for SSH and SMB
#   03) Lubuntu 24.04 VM as AD-joined NFS gateway
#   04) Data source for latest Ubuntu 24.04 LTS image
#
# Key Points:
#   - Random suffix prevents name collisions
#   - SSH and SMB rules open to 0.0.0.0/0 (lab only)
#   - VM runs startup script to join AD and mount NFS
#   - Uses service account for GCP API access
# ================================================================================


# ================================================================================
# Random String Generator
# --------------------------------------------------------------------------------
# Generates 10-character lowercase suffix for uniqueness.
# ================================================================================
resource "random_string" "vm_suffix" {
  length  = 10    # Number of characters in generated string
  special = false # Exclude special characters (DNS-friendly)
  upper   = false # Lowercase only for consistency
}


# ================================================================================
# Firewall Rule: Allow SSH
# --------------------------------------------------------------------------------
# Opens TCP port 22 for instances tagged with allow-ssh.
#
# Key Points:
#   - Tag-based targeting
#   - Source range 0.0.0.0/0 (restrict in production)
# ================================================================================
resource "google_compute_firewall" "allow_ssh" {
  name    = "lubuntu-allow-ssh"
  network = var.vpc

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Applies only to instances with this tag
  target_tags = ["lubuntu-allow-ssh"]

  # Lab only; tighten for production
  source_ranges = ["0.0.0.0/0"]
}

# ================================================================================
# Firewall Rule: Allow SMB
# --------------------------------------------------------------------------------
# Opens TCP port 445 for instances tagged with allow-smb.
#
# Key Points:
#   - Tag-based targeting
#   - Source range 0.0.0.0/0 (restrict in production)
# ================================================================================
resource "google_compute_firewall" "allow_smb" {
  name    = "lubuntu-allow-smb"
  network = var.vpc

  allow {
    protocol = "tcp"
    ports    = ["445"]
  }

  # Applies only to instances with this tag
  target_tags = ["lubuntu-allow-smb"]

  # Lab only; tighten for production
  source_ranges = ["0.0.0.0/0"]
}


# ================================================================================
# Lubuntu VM: NFS Gateway + AD-Joined Desktop Client
# --------------------------------------------------------------------------------
# Deploys Lubuntu 24.04 VM that:
#   - Connects to ad-vpc and ad-subnet
#   - Boots from Packer-built image
#   - Runs startup script to join AD and mount Filestore NFS
#   - Uses OS Login for secure SSH
#
# Key Points:
#   - Startup injects domain FQDN and Filestore IP
#   - Service account grants required API access
# ================================================================================
resource "google_compute_instance" "desktop_instance" {
  name         = "lubuntu-${random_string.vm_suffix.result}"
  machine_type = "n2-standard-4"
  zone         = "us-central1-a"

  # ------------------------------------------------------------------------------
  # Boot Disk
  # ------------------------------------------------------------------------------
  boot_disk {
    initialize_params {
      image = data.google_compute_image.lubuntu_packer_image.self_link
    }
  }

  # ------------------------------------------------------------------------------
  # Network Interface
  # ------------------------------------------------------------------------------
  network_interface {
    network    = var.vpc
    subnetwork = var.subnet

    # Ephemeral public IP for SSH access
    access_config {}
  }

  # ------------------------------------------------------------------------------
  # Metadata (Startup Script + Config)
  # ------------------------------------------------------------------------------
  metadata = {
    enable-oslogin = "TRUE" # Enforce OS Login

    startup-script = templatefile("./scripts/nfs_gateway_init.sh", {
      domain_fqdn   = "mcloud.mikecloud.com"
      nfs_server_ip = google_filestore_instance.nfs_server.networks[0].ip_addresses[0]
      domain_fqdn   = var.dns_zone
      netbios       = var.netbios
      force_group   = "mcloud-users"
      realm         = var.realm
    })
  }

  # ------------------------------------------------------------------------------
  # Service Account
  # ------------------------------------------------------------------------------
  service_account {
    email  = local.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # ------------------------------------------------------------------------------
  # Firewall Tags
  # ------------------------------------------------------------------------------
  # Applies SSH and SMB firewall rules
  tags = ["lubuntu-allow-ssh", "lubuntu-allow-nfs", "lubuntu-allow-smb", "lubuntu-allow-rdp"]
}


# ================================================================================
# Data Source: Latest Ubuntu 24.04 LTS Image
# --------------------------------------------------------------------------------
# Fetch most recent Ubuntu 24.04 LTS image.
# Ensures VMs launch with patched image.
# ================================================================================
data "google_compute_image" "ubuntu_latest" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}