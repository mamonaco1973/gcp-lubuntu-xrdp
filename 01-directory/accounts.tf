# ================================================================================================
# Active Directory User Credentials in GCP Secret Manager
# ================================================================================================
# Provisions:
#   1. Memorable passwords for each AD user: <word>-<6digit>
#   2. Secret Manager entries for storing credentials.
#   3. IAM bindings granting the service account access to retrieve these secrets.
#
# Key Points:
#   - Users: Admin, John Smith, Emily Davis, Raj Patel, Amit Kumar.
#   - Password format: "<memorable_word>-<6digit>" (one word + one number per user).
#   - Secrets stored securely in GCP Secret Manager.
#   - Service account is granted `roles/secretmanager.secretAccessor` on all secrets.
# ================================================================================================

# ================================================================================================
# Memorable Word List
# ================================================================================================
locals {
  memorable_words = [
    "bright",
    "simple",
    "orange",
    "window",
    "little",
    "people",
    "friend",
    "yellow",
    "animal",
    "family",
    "circle",
    "moment",
    "summer",
    "button",
    "planet",
    "rocket",
    "silver",
    "forest",
    "stream",
    "butter",
    "castle",
    "wonder",
    "gentle",
    "driver",
    "coffee"
  ]
}

# ================================================================================================
# User Accounts to Generate
# ================================================================================================
locals {
  ad_users = {
    admin  = "Admin"
    jsmith = "John Smith"
    edavis = "Emily Davis"
    rpatel = "Raj Patel"
    akumar = "Amit Kumar"
  }
}

# ================================================================================================
# Random Word (one per user)
# ================================================================================================
resource "random_shuffle" "word" {
  for_each     = local.ad_users
  input        = local.memorable_words
  result_count = 1
}

# ================================================================================================
# Random 6-digit number (one per user)
# ================================================================================================
resource "random_integer" "num" {
  for_each = local.ad_users
  min      = 100000
  max      = 999999
}

# ================================================================================================
# Build the Password: <word>-<number>
# ================================================================================================
locals {
  passwords = {
    for user, fullname in local.ad_users :
    user => "${random_shuffle.word[user].result[0]}-${random_integer.num[user].result}"
  }
}

# ================================================================================================
# Create Secret + Version for Each User
# ================================================================================================
resource "google_secret_manager_secret" "ad_secret" {
  for_each  = local.ad_users
  secret_id = "${each.key}-ad-credentials"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ad_secret_version" {
  for_each = local.ad_users
  secret  = google_secret_manager_secret.ad_secret[each.key].id

  secret_data = jsonencode({
    username = "${each.key}@${var.dns_zone}"
    password = local.passwords[each.key]
  })
}

# ================================================================================================
# Locals: Secret List
# ================================================================================================
locals {
  secrets = [
    for user, fullname in local.ad_users :
    google_secret_manager_secret.ad_secret[user].secret_id
  ]
}

# ================================================================================================
# IAM Binding: Grant Secret Access
# ================================================================================================
resource "google_secret_manager_secret_iam_binding" "secret_access" {
  for_each  = toset(local.secrets)
  secret_id = each.key
  role      = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${local.service_account_email}"
  ]
}
