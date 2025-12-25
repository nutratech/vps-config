#!/bin/bash

# Stop on error
set -e

DOMAIN="nutra.tk"

# Detect the real user (if running with sudo) or fall back to current user
REAL_USER="${SUDO_USER:-$USER}"

echo ">>> Starting setup for $REAL_USER on $DOMAIN..."

echo ">>> Updating System..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring git make tree ripgrep direnv htop

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 1. Firewall (UFW)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo ">>> Configuring Firewall..."
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh              # Port 22
sudo ufw allow http             # Port 80
sudo ufw allow https            # Port 443 (TCP)
sudo ufw allow 443/udp          # Port 443 (QUIC/HTTP3)
sudo ufw --force enable

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 2. Fail2Ban
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo ">>> Installing Fail2Ban..."
sudo apt install -y fail2ban
# Copy default config to local to avoid overwrite on update
sudo cp -n /etc/fail2ban/jail.conf /etc/fail2ban/jail.local || true
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 3. Nginx (Official Repo for HTTP/3)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo ">>> Installing Nginx (Mainline)..."
# Remove default ubuntu nginx if present to avoid conflicts
sudo apt remove -y nginx nginx-common nginx-core || true

# Add official Nginx signing key
curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

# Verify fingerprint (optional, for log output)
gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg

# Add Repo source
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    https://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list

sudo apt update
sudo apt install -y nginx

# Setup web directories
echo ">>> Setting up /var/www/app permissions for $REAL_USER..."
sudo mkdir -p /var/www/app
sudo chown -R $REAL_USER:$REAL_USER /var/www/app

# Enable service
sudo systemctl enable nginx
sudo systemctl start nginx

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 4. Certbot (Venv Method)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo ">>> Installing Certbot..."
sudo apt install -y python3 python3-venv libaugeas0
sudo python3 -m venv /opt/certbot/
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-nginx
sudo ln -sf /opt/certbot/bin/certbot /usr/bin/certbot

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 5. Cron Jobs
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo ">>> Configuring Certbot Auto-Renewal..."

# Create the cron file content directly
cat <<EOF | sudo tee /etc/cron.d/certbot-renew
# /etc/cron.d/certbot-renew: Run twice daily
0 0,12 * * * root /opt/certbot/bin/certbot renew -q --post-hook "systemctl reload nginx"
EOF

# Secure permissions
sudo chmod 644 /etc/cron.d/certbot-renew

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 6. User & Git Config
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo ">>> Setting up 'github' user..."
if id "github" &>/dev/null; then
    echo "User 'github' already exists."
else
    sudo useradd -m -s /bin/bash github
    sudo -u github mkdir -p /home/github/.ssh
    echo "User 'github' created."
fi

echo ">>> Done! Don't forget to:"
echo "1. Run certbot manually once: sudo certbot --nginx -d $DOMAIN"
echo "2. Copy your nginx config files to /etc/nginx/conf.d/"
