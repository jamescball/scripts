#!/usr/bin/env bash
#
# Harden SSH on Ubuntu using a given public key and additional security settings.

set -e

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or via sudo."
  exit 1
fi

echo "=== Installing OpenSSH server (if not already) ==="
apt-get update -y
apt-get install -y openssh-server

# Create ~/.ssh if it doesn't exist, and set permissions
if [[ ! -d "$HOME/.ssh" ]]; then
  echo "=== Creating ~/.ssh directory ==="
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
fi

# Define the public key you want to add
SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAh4PJHN3wRuGhjvXn6MZcksxHt279G7bM9H+qL1zNiDxLxbFRTpe8go74W1/UEgIUVqaIw0MgjpSCD9hPzo1wciUfvomD/YrTlPdovaqIdui5IYgX3Ge4AH2Pwu8HtNT5nQzoEmb2FEunEw5EafT/bGwn9WgnvVOlOaKE5yG48m7QzmP0jwagwt+bsVUnmBQryN1MQD35g+w4Ki2OsJnMcE//gWfUhnvrqV2815xnjB8R4swzdZRPZMcs9TVL1HKTZcRqFEqTSWd7HOE7byEdf8p57fqJ1ZEVbQJBRA+Y9sq/P89eL1FzXL9AuLMS59V46xHD9fU24AGCMcRUkQzQ+w== rsa-key-20201007"

AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"

# Create authorized_keys if it doesn't exist, with correct permissions
if [[ ! -f "$AUTHORIZED_KEYS" ]]; then
  echo "=== Creating authorized_keys file ==="
  touch "$AUTHORIZED_KEYS"
  chmod 600 "$AUTHORIZED_KEYS"
fi

# Check if the key is already in authorized_keys; if not, add it
if ! grep -q "$SSH_PUBLIC_KEY" "$AUTHORIZED_KEYS"; then
  echo "=== Adding provided public key to authorized_keys ==="
  echo "$SSH_PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
else
  echo "=== Public key already present in authorized_keys ==="
fi

echo "=== Hardening SSH configuration ==="
SSHD_CONFIG="/etc/ssh/sshd_config"

# Backup the current sshd_config
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak.$(date +%F-%T)"

# Disable root login
sed -i 's/#\?PermitRootLogin.*/PermitRootLogin no/g' "$SSHD_CONFIG"

# Disable password authentication
sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication no/g' "$SSHD_CONFIG"

# Enable public key authentication
sed -i 's/#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g' "$SSHD_CONFIG"

# Disable challenge-response authentication
sed -i 's/#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/g' "$SSHD_CONFIG"

# ------------------
# Additional Hardening
# ------------------

# Limit the maximum number of authentication attempts per connection
sed -i 's/#\?MaxAuthTries.*/MaxAuthTries 3/g' "$SSHD_CONFIG"

# Ignore .rhosts and .shosts files
sed -i 's/#\?IgnoreRhosts.*/IgnoreRhosts yes/g' "$SSHD_CONFIG"

# Disable host-based authentication
sed -i 's/#\?HostbasedAuthentication.*/HostbasedAuthentication no/g' "$SSHD_CONFIG"

# Disallow empty passwords
sed -i 's/#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' "$SSHD_CONFIG"

# Disable X11 forwarding
sed -i 's/#\?X11Forwarding.*/X11Forwarding no/g' "$SSHD_CONFIG"

# Disable DNS lookups to speed up SSH connections
sed -i 's/#\?UseDNS.*/UseDNS no/g' "$SSHD_CONFIG"

# If you want to restrict SSH to a specific user or users, uncomment this:
# echo "AllowUsers your_user" >> "$SSHD_CONFIG"

echo "=== Restarting SSH service to apply changes ==="
systemctl restart ssh

echo "=== SSH setup and hardening complete! ==="
echo " - Root login is disabled."
echo " - Password authentication is disabled."
echo " - Public key authentication is enabled."
echo " - Challenge-response authentication is disabled."
echo " - MaxAuthTries is set to 3."
echo " - IgnoreRhosts is set to yes."
echo " - HostbasedAuthentication is disabled."
echo " - PermitEmptyPasswords is no."
echo " - X11Forwarding is no."
echo " - UseDNS is no."
echo "Remember to keep your private key secure."
