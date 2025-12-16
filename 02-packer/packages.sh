#!/bin/bash
set -euo pipefail

# ==========================================================================================
# This script prepares an Ubuntu host for:
#   - Active Directory domain joins using realmd, SSSD, and adcli
#   - NSS/PAM integration for domain users and automatic home directory creation
#   - Samba utilities required for Kerberos, NTLM, and domain discovery
# ==========================================================================================

# ------------------------------------------------------------------------------------------
# XRDP has issues with snap so disable and remove it first
# ------------------------------------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

echo "NOTE: Waiting for snap seeding to finish..."
while snap changes | grep -qE 'Doing|Wait'; do
  sleep 5
done

sudo snap remove --purge google-cloud-cli
sudo snap remove --purge core22 || true
sudo snap remove --purge snapd || true
sudo apt-get purge -y snapd
sudo apt-get autoremove -y --purge
sudo rm -rf /var/cache/snapd /var/lib/snapd ~/snap

echo -e "Package: snapd\nPin: release *\nPin-Priority: -10" \
  | sudo tee /etc/apt/preferences.d/nosnap.pref >/dev/null

sudo apt-get update -y

# ------------------------------------------------------------------------------------------
# Install Core AD, NSS, Samba, Kerberos, NFS, and Utility Packages
# ------------------------------------------------------------------------------------------
# Includes:
#   - realmd / adcli / krb5-user     : Domain discovery and Kerberos auth
#   - sssd-ad / libnss-sss / libpam-sss : Identity + authentication via SSSD
#   - samba-common-bin / samba-libs  : Required for domain membership operations
#   - oddjob / oddjob-mkhomedir      : Auto-create home directories for AD users
#   - nfs-common                     : Required for EFS and NFS mounts
#   - stunnel4                       : Enables TLS for amazon-efs-utils
#   - less / unzip / nano / vim      : Basic utilities
# ------------------------------------------------------------------------------------------

apt-get install -y less unzip realmd sssd-ad sssd-tools libnss-sss \
    libpam-sss adcli samba samba-common-bin samba-libs oddjob \
    oddjob-mkhomedir packagekit krb5-user nano vim nfs-common \
    winbind libpam-winbind libnss-winbind stunnel4 jq

