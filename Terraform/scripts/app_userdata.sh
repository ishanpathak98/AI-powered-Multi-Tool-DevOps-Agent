#!/bin/bash
# terraform/scripts/app_userdata.sh
# User data script for application servers with Node Exporter, Docker, Python

set -e

# Variables from Terraform
PROMETHEUS_SERVER="${prometheus_server}"
LOKI_SERVER="${loki_server}"
CLOUDWATCH_LOG_GROUP="${cloudwatch_log_group}"
PROJECT_NAME="${project_name}"
NODE_EXPORTER_VERSION="1.7.0"  # <-- Hardcoded instead of passing from Terraform

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /var/log/user-data.log
}

log "Starting user data script for application server"

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
    ufw

# Configure UFW firewall
log "Configuring UFW firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8501/tcp
ufw allow 9100/tcp
ufw allow from "$PROMETHEUS_SERVER" to any port 9100

# Install Docker
log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Install Docker Compose
log "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Python
log "Installing Python and essential packages..."
apt-get install -y python3.9 python3.9-venv python3.9-dev python3-pip
update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
python3 -m pip install --upgrade pip
pip3 install \
    requests boto3 prometheus-client langchain openai streamlit pandas numpy \
    psutil docker slack-sdk python-dotenv pyyaml watchdog schedule click rich \
    typer fastapi uvicorn sqlalchemy prometheus-api-client grafana-api loki-logger-handler

# Install Node.js and npm
log "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install Prometheus Node Exporter
log "Installing Prometheus Node Exporter..."
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*
useradd --no-create-home --shell /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --collector.systemd \
    --collector.processes \
    --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

# Remaining setup continues... (unchanged)
