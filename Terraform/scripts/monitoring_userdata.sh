#!/bin/bash
# terraform/scripts/monitoring_userdata.sh
# User data script for monitoring server with Prometheus, Grafana, and Loki

set -e

# Variables from Terraform
GRAFANA_ADMIN_PASSWORD="${grafana_admin_password}"
CLOUDWATCH_LOG_GROUP="${cloudwatch_log_group}"
PROJECT_NAME="${project_name}"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /var/log/user-data.log
}

log "Starting user data script for monitoring server"

# Update system
log "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install essential packages
log "Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    unzip \
    jq \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    awscli \
    build-essential \
    python3-dev \
    python3-pip \
    python3-venv \
    supervisor \
    nginx \
    certbot \
    fail2ban \
    ufw \
    sqlite3

# Configure UFW firewall
log "Configuring UFW firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp  # Grafana
ufw allow 9090/tcp  # Prometheus
ufw allow 3100/tcp  # Loki
ufw allow 9093/tcp  # Alertmanager

# Install Docker
log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Docker Compose
log "Installing Docker Compose..."
