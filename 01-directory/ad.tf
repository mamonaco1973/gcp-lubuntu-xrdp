# ================================================================================
# Mini Active Directory (mini-ad) Module Invocation
# --------------------------------------------------------------------------------
# Purpose:
#   - Calls reusable "mini-ad" module to provision Ubuntu AD controller
#   - Passes networking, DNS, and authentication parameters
#   - Supplies user accounts via rendered JSON template blob
# ================================================================================

module "mini_ad" {
  source            = "github.com/mamonaco1973/module-gcp-mini-ad" # Path to mini-ad Terraform module
  netbios           = var.netbios                                  # NetBIOS domain name (e.g., MCLOUD)
  network           = google_compute_network.ad_vpc.id             # VPC where AD will reside
  realm             = var.realm                                    # Kerberos realm (UPPERCASE DNS domain)
  users_json        = local.users_json                             # JSON blob of users and passwords
  user_base_dn      = var.user_base_dn                             # Base DN for user accounts in LDAP
  ad_admin_password = local.passwords["admin"]                     # Randomized AD admin password
  dns_zone          = var.dns_zone                                 # DNS zone (e.g., mcloud.mikecloud.com)
  subnetwork        = google_compute_subnetwork.ad_subnet.id       # Subnet for AD VM placement
  email             = local.service_account_email                  # Service account email
  machine_type      = var.machine_type                             # Machine type for AD VM

  # Ensure NAT and route association exist before bootstrap
  # Required for package repositories and external access
  depends_on = [
    google_compute_subnetwork.ad_subnet,
    google_compute_router.ad_router,
    google_compute_router_nat.ad_nat
  ]
}

# ================================================================================
# Local Variable: users_json
# --------------------------------------------------------------------------------
#   - Renders users.json.template into single JSON blob
#   - Injects unique random passwords for demo users
#   - Template variables replaced with runtime values
#   - Passed into VM bootstrap for automatic user creation
# ================================================================================

locals {
  users_json = templatefile("./scripts/users.json.template", {
    USER_BASE_DN    = var.user_base_dn            # Base DN for placing users in LDAP
    DNS_ZONE        = var.dns_zone                # AD-integrated DNS zone
    REALM           = var.realm                   # Kerberos realm (FQDN uppercase)
    NETBIOS         = var.netbios                 # NetBIOS domain name
    jsmith_password = local.passwords["jsmith"]  # Random password for John Smith
    edavis_password = local.passwords["edavis"]  # Random password for Emily Davis
    rpatel_password = local.passwords["rpatel"]  # Random password for Raj Patel
    akumar_password = local.passwords["akumar"]  # Random password for Amit Kumar
  })
}