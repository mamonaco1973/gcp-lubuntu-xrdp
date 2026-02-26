# ================================================================================
# SysAdmin Credentials + Windows AD Management VM with RDP Firewall
# --------------------------------------------------------------------------------
# Provisions:
#   01) SysAdmin password stored in Secret Manager
#   02) Firewall rule allowing inbound RDP (3389)
#   03) Windows Server 2022 AD management VM
#   04) Data source for latest Windows Server 2022 image
#
# Key Points:
#   - Credentials stored securely in Secret Manager
#   - Firewall rules are tag-based in GCP
#   - RDP open to 0.0.0.0/0 (lab only)
#   - VM auto-joins AD using startup PowerShell script
# ================================================================================


# ================================================================================
# SysAdmin Credentials
# --------------------------------------------------------------------------------
# Generate random SysAdmin password and store in Secret Manager.
# ================================================================================
resource "random_password" "sysadmin_password" {
  length           = 24
  special          = true
  override_special = "-_."
}

resource "google_secret_manager_secret" "sysadmin_secret" {
  secret_id = "sysadmin-ad-credentials-lubuntu"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "admin_secret_version" {
  secret = google_secret_manager_secret.sysadmin_secret.id
  secret_data = jsonencode({
    username = "sysadmin"
    password = random_password.sysadmin_password.result
  })
}


# ================================================================================
# Firewall Rule: Allow RDP
# --------------------------------------------------------------------------------
# Allow inbound RDP (TCP 3389) to instances tagged allow-rdp.
#
# Key Points:
#   - Applies only to instances with allow-rdp tag
#   - Source 0.0.0.0/0 is lab-only; restrict in production
# ================================================================================
resource "google_compute_firewall" "allow_rdp" {
  name    = "lubuntu-allow-rdp"
  network = "ad-vpc"

  # Allow TCP 3389 (RDP)
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  # Apply only to instances with this tag
  target_tags = ["lubuntu-allow-rdp"]

  # Lab only; restrict for production
  source_ranges = ["0.0.0.0/0"]
}


# ================================================================================
# Windows AD Management VM
# --------------------------------------------------------------------------------
# Deploy Windows Server 2022 VM for AD admin and domain join tasks.
#
# Key Points:
#   - Uses latest Windows 2022 image
#   - Tagged allow-rdp for firewall rule
#   - Startup script joins AD domain
#   - Admin credentials passed via metadata
# ================================================================================
resource "google_compute_instance" "windows_ad_instance" {
  name         = "win-ad-${random_string.vm_suffix.result}" # Random suffix
  machine_type = "e2-standard-2"                            # Balanced size
  zone         = "us-central1-a"

  # ------------------------------------------------------------------------------
  # Boot Disk (Windows Server 2022)
  # ------------------------------------------------------------------------------
  boot_disk {
    initialize_params {
      image = data.google_compute_image.windows_2022.self_link
    }
  }

  # ------------------------------------------------------------------------------
  # Network Interface
  # ------------------------------------------------------------------------------
  network_interface {
    network    = var.vpc
    subnetwork = var.subnet

    # Assign public IP for RDP access
    access_config {}
  }

  # ------------------------------------------------------------------------------
  # Service Account
  # ------------------------------------------------------------------------------
  # Grants VM access to GCP APIs
  service_account {
    email  = local.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # ------------------------------------------------------------------------------
  # Startup Script (Domain Join)
  # ------------------------------------------------------------------------------
  # Runs at first boot to join AD domain
  metadata = {
    windows-startup-script-ps1 = templatefile("./scripts/ad_join.ps1", {
      domain_fqdn = "mcloud.mikecloud.com"
      nfs_gateway = google_compute_instance.desktop_instance.network_interface[0].network_ip
    })

    admin_username = "sysadmin"
    admin_password = random_password.sysadmin_password.result
  }

  # ------------------------------------------------------------------------------
  # Firewall Tags
  # ------------------------------------------------------------------------------
  # Applies allow-rdp firewall rule
  tags = ["lubuntu-allow-rdp"]
}


# ================================================================================
# Data Source: Latest Windows Server 2022 Image
# --------------------------------------------------------------------------------
# Fetch latest Windows Server 2022 image from windows-cloud project.
# Ensures deployments use patched OS image.
# ================================================================================
data "google_compute_image" "windows_2022" {
  family  = "windows-2022"
  project = "windows-cloud"
}