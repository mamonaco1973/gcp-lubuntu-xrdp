# ==============================================================================
# Active Directory Naming Inputs
# ------------------------------------------------------------------------------
# - dns_zone : FQDN for the AD DNS zone / domain.
# - realm    : Kerberos realm (usually dns_zone in UPPERCASE).
# - netbios  : Short pre-Windows 2000 domain name.
# ==============================================================================

# ------------------------------------------------------------------------------
# DNS zone / AD domain (FQDN)
# Used by Samba AD DC for DNS namespace and domain identity.
# ------------------------------------------------------------------------------
variable "dns_zone" {
  description = "AD DNS zone / domain (e.g., mcloud.mikecloud.com)"
  type        = string
  default     = "mcloud.mikecloud.com"
}

# ------------------------------------------------------------------------------
# Kerberos realm (UPPERCASE)
# Convention: match dns_zone but uppercase.
# Required by Kerberos configuration.
# ------------------------------------------------------------------------------
variable "realm" {
  description = "Kerberos realm (usually DNS zone in UPPERCASE, e.g., MCLOUD.MIKECLOUD.COM)"
  type        = string
  default     = "MCLOUD.MIKECLOUD.COM"
}

# ------------------------------------------------------------------------------
# NetBIOS short domain name
# Typically <= 15 characters, uppercase alphanumerics.
# Used by legacy clients and some SMB flows.
# ------------------------------------------------------------------------------
variable "netbios" {
  description = "NetBIOS short domain name (e.g., MCLOUD)"
  type        = string
  default     = "MCLOUD"
}

# ------------------------------------------------------------------------------
# User base DN for LDAP
# ------------------------------------------------------------------------------
variable "user_base_dn" {
  description = "User base DN for LDAP (e.g., CN=Users,DC=mcloud,DC=mikecloud,DC=com)"
  type        = string
  default     = "CN=Users,DC=mcloud,DC=mikecloud,DC=com"
}

# ------------------------------------------------------------------------------
# Zone for deployment
# ------------------------------------------------------------------------------
variable "zone" {
  description = "GCP zone for deployment (e.g., us-central1-a)"
  type        = string
  default     = "us-central1-a"
}

# ------------------------------------------------------------------------------
# Machine type for mini AD instance
# ------------------------------------------------------------------------------
variable "machine_type" {
  description = "Machine type for mini AD instance (minimum is e2-small)"
  type        = string
  default     = "e2-medium"
}

# ==============================================================================
# VPC Name for Mini AD Instance
# ------------------------------------------------------------------------------
# Name of the VPC network where the AD instance will reside.
# ==============================================================================
variable "vpc" {
  description = "Network for mini AD instance (e.g., ad-vpc)"
  type        = string
  default     = "lubuntu-vpc"
}

# ==============================================================================
# Subnet Name for Mini AD Instance
# ------------------------------------------------------------------------------
# Name of the subnet within the VPC used for AD placement.
# ==============================================================================
variable "subnet" {
  description = "Sub-network for mini AD instance (e.g., ad-subnet)"
  type        = string
  default     = "lubuntu-subnet"
}