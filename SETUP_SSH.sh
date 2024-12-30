#!/usr/bin/env bash
#
# Harden SSH on Ubuntu using a given public key,
# disable root login and password auth,
# move SSH to port 47, and apply additional security tweaks.

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

# Change SSH port to 47
sed -i 's/#\?Port.*/Port 47/g' "$SSHD_CONFIG"

# Disable root login
sed -i 's/#\?PermitRootLogin.*/PermitRootLogin no/g' "$SSHD_CONFIG"

# Disable password authentication
sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication no/g' "$SSHD_CONFIG"

# Enable public key authentication
sed -i 's/#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g' "$SSHD_CONFIG"

# Disable challenge-response authentication
sed -i 's/#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/g' "$SSHD_CONFIG"

# Additional hardening
sed -i 's/#\?MaxAuthTries.*/MaxAuthTries 3/g' "$SSHD_CONFIG"
sed -i 's/#\?IgnoreRhosts.*/IgnoreRhosts yes/g' "$SSHD_CONFIG"
sed -i 's/#\?HostbasedAuthentication.*/HostbasedAuthentication no/g' "$SSHD_CONFIG"
sed -i 's/#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' "$SSHD_CONFIG"
sed -i 's/#\?X11Forwarding.*/X11Forwarding no/g' "$SSHD_CONFIG"
sed -i 's/#\?UseDNS.*/UseDNS no/g' "$SSHD_CONFIG"

echo "=== Restarting SSH service to apply changes ==="
systemctl restart ssh

# Optional: Update your firewall rules (e.g., UFW) to allow connections on port 47
# ufw allow 47/tcp

echo "=== SSH setup and hardening complete! ==="
echo " - Listening on port 47."
echo " - Root login is disabled."
echo " - Password authentication is disabled."
echo " - Only key-based authentication is allowed."
echo " - MaxAuthTries is set to 3, X11Forwarding is off, and other security tweaks are applied."
echo " - Remember to keep your private key secure."

echo
echo "=== NOTE: Ensure your firewall is configured to allow port 47. ==="
echo "=== Also verify SSH connectivity on the new port before disconnecting! ==="
