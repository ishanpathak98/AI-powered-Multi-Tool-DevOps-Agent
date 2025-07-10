#!/bin/bash
# terraform/scripts/app_userdata.sh
# User data script for application servers with Node Exporter, Docker, Python

set -e

# Variables from Terraform
PROMETHEUS_SERVER="${prometheus_server}"
LOKI_SERVER="${loki_server}"
CLOUDWATCH_LOG_GROUP="${cloudwatch_log_group}"
PROJECT_NAME="${project_name}"

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
ufw allow from ${PROMETHEUS_SERVER} to any port 9100

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
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create docker-compose symlink
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Python and pip
log "Installing Python and essential packages..."
apt-get install -y python3.9 python3.9-venv python3.9-dev python3-pip

# Update alternatives for python
update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

# Upgrade pip
python3 -m pip install --upgrade pip

# Install essential Python packages
pip3 install \
    requests \
    boto3 \
    prometheus-client \
    langchain \
    openai \
    streamlit \
    pandas \
    numpy \
    psutil \
    docker \
    slack-sdk \
    python-dotenv \
    pyyaml \
    watchdog \
    schedule \
    click \
    rich \
    typer \
    fastapi \
    uvicorn \
    sqlalchemy \
    prometheus-api-client \
    grafana-api \
    loki-logger-handler

# Install Node.js and npm (for potential frontend needs)
log "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install Prometheus Node Exporter
log "Installing Prometheus Node Exporter..."
NODE_EXPORTER_VERSION="1.7.0"
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

# Create node_exporter user
useradd --no-create-home --shell /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create Node Exporter systemd service
cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \\
    --collector.systemd \\
    --collector.processes \\
    --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Node Exporter
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

# Install cAdvisor for container monitoring
log "Installing cAdvisor..."
docker run -d \
  --name=cadvisor \
  --restart=unless-stopped \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  gcr.io/cadvisor/cadvisor:latest

# Install Promtail for log shipping to Loki
log "Installing Promtail..."
PROMTAIL_VERSION="2.9.3"
cd /tmp
wget https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
chmod +x promtail-linux-amd64
mv promtail-linux-amd64 /usr/local/bin/promtail

# Create promtail user
useradd --no-create-home --shell /bin/false promtail
mkdir -p /etc/promtail
chown promtail:promtail /etc/promtail

# Create Promtail configuration
cat > /etc/promtail/promtail.yaml << EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://${LOKI_SERVER}:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log
          host: $(hostname)

  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*log
          host: $(hostname)

  - job_name: devops-agent
    static_configs:
      - targets:
          - localhost
        labels:
          job: devops-agent
          __path__: /opt/devops-agent/logs/*.log
          host: $(hostname)
EOF

# Create Promtail systemd service
cat > /etc/systemd/system/promtail.service << EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=promtail
ExecStart=/usr/local/bin/promtail -config.file /etc/promtail/promtail.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Promtail
systemctl daemon-reload
systemctl start promtail
systemctl enable promtail

# Create application directory structure
log "Creating application directory structure..."
mkdir -p /opt/devops-agent/{src,logs,config,data,scripts}
mkdir -p /opt/devops-agent/src/{agents,tools,utils,monitoring}

# Set permissions
chown -R ubuntu:ubuntu /opt/devops-agent
chmod -R 755 /opt/devops-agent

# Create CloudWatch agent configuration
log "Installing and configuring CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Create CloudWatch agent configuration file
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "${CLOUDWATCH_LOG_GROUP}",
            "log_stream_name": "{instance_id}/syslog"
          },
          {
            "file_path": "/var/log/auth.log",
            "log_group_name": "${CLOUDWATCH_LOG_GROUP}",
            "log_stream_name": "{instance_id}/auth"
          },
          {
            "file_path": "/opt/devops-agent/logs/*.log",
            "log_group_name": "${CLOUDWATCH_LOG_GROUP}",
            "log_stream_name": "{instance_id}/devops-agent"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "DevOps-Agent",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"],
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "diskio": {
        "measurement": [
          "io_time"
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Create sample application with CPU stress testing capability
log "Creating sample application..."
cat > /opt/devops-agent/src/sample_app.py << 'EOF'
#!/usr/bin/env python3
"""
Sample application for DevOps AI Agent testing
Includes CPU stress testing and monitoring endpoints
"""

import os
import time
import psutil
import threading
import streamlit as st
from prometheus_client import Counter, Histogram, Gauge, start_http_server
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/opt/devops-agent/logs/app.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total requests')
REQUEST_LATENCY = Histogram('app_request_duration_seconds', 'Request latency')
CPU_USAGE = Gauge('app_cpu_usage_percent', 'CPU usage percentage')
MEMORY_USAGE = Gauge('app_memory_usage_percent', 'Memory usage percentage')
ACTIVE_THREADS = Gauge('app_active_threads', 'Active threads')

class CPUStressTester:
    def __init__(self):
        self.stress_active = False
        self.stress_threads = []
    
    def cpu_stress_worker(self, duration):
        """Worker function for CPU stress testing"""
        end_time = time.time() + duration
        while time.time() < end_time and self.stress_active:
            # Intensive CPU work
            for i in range(1000000):
                _ = i ** 2
    
    def start_stress_test(self, duration=300, num_threads=4):
        """Start CPU stress test"""
        if self.stress_active:
            return False
        
        self.stress_active = True
        self.stress_threads = []
        
        logger.info(f"Starting CPU stress test for {duration} seconds with {num_threads} threads")
        
        for i in range(num_threads):
            thread = threading.Thread(
                target=self.cpu_stress_worker,
                args=(duration,),
                name=f"StressThread-{i}"
            )
            thread.start()
            self.stress_threads.append(thread)
        
        return True
    
    def stop_stress_test(self):
        """Stop CPU stress test"""
        self.stress_active = False
        for thread in self.stress_threads:
            thread.join()
        self.stress_threads = []
        logger.info("CPU stress test stopped")

def update_metrics():
    """Update Prometheus metrics"""
    while True:
        try:
            CPU_USAGE.set(psutil.cpu_percent(interval=1))
            MEMORY_USAGE.set(psutil.virtual_memory().percent)
            ACTIVE_THREADS.set(threading.active_count())
            time.sleep(10)
        except Exception as e:
            logger.error(f"Error updating metrics: {e}")

# Initialize components
stress_tester = CPUStressTester()

# Start Prometheus metrics server
start_http_server(8000)

# Start metrics update thread
metrics_thread = threading.Thread(target=update_metrics, daemon=True)
metrics_thread.start()

# Streamlit UI
st.title("DevOps AI Agent - Test Application")
st.write("This application helps test the DevOps AI Agent monitoring and remediation capabilities.")

# System Information
st.header("System Information")
col1, col2, col3 = st.columns(3)

with col1:
    st.metric("CPU Usage", f"{psutil.cpu_percent()}%")
    
with col2:
    st.metric("Memory Usage", f"{psutil.virtual_memory().percent}%")
    
with col3:
    st.metric("Active Threads", threading.active_count())

# CPU Stress Test Controls
st.header("CPU Stress Test")
col1, col2 = st.columns(2)

with col1:
    duration = st.slider("Duration (seconds)", 30, 600, 300)
    threads = st.slider("Number of threads", 1, 8, 4)

with col2:
    if st.button("Start Stress Test"):
        if stress_tester.start_stress_test(duration, threads):
            st.success(f"Started CPU stress test for {duration} seconds")
            REQUEST_COUNT.inc()
        else:
            st.error("Stress test already running")
    
    if st.button("Stop Stress Test"):
        stress_tester.stop_stress_test()
        st.success("Stopped CPU stress test")

# Logs
st.header("Recent Logs")
try:
    with open('/opt/devops-agent/logs/app.log', 'r') as f:
        logs = f.readlines()[-10:]  # Last 10 lines
    st.text_area("Log Output", "\n".join(logs), height=200)
except FileNotFoundError:
    st.info("No logs available yet")

# Health Check endpoint
st.header("Health Status")
st.json({
    "status": "healthy",
    "timestamp": datetime.now().isoformat(),
    "cpu_usage": psutil.cpu_percent(),
    "memory_usage": psutil.virtual_memory().percent,
    "disk_usage": psutil.disk_usage('/').percent,
    "active_threads": threading.active_count()
})

if __name__ == "__main__":
    logger.info("Sample application started")
EOF

# Create systemd service for the sample application
cat > /etc/systemd/system/devops-sample-app.service << EOF
[Unit]
Description=DevOps AI Agent Sample Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/devops-agent/src
ExecStart=/usr/bin/python3 -m streamlit run sample_app.py --server.port=8501 --server.address=0.0.0.0
Restart=on-failure
Environment=PYTHONPATH=/opt/devops-agent/src

[Install]
WantedBy=multi-user.target
EOF

# Create log rotation configuration
cat > /etc/logrotate.d/devops-agent << EOF
/opt/devops-agent/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        systemctl reload promtail
    endscript
}
EOF

# Enable and start services
systemctl daemon-reload
systemctl enable devops-sample-app
systemctl start devops-sample-app

# Install and configure Nginx as reverse proxy
log "Configuring Nginx..."
cat > /etc/nginx/sites-available/devops-agent << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:8501;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    location /metrics {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable the site
ln -s /etc/nginx/sites-available/devops-agent /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Create startup script
cat > /opt/devops-agent/scripts/startup.sh << 'EOF'
#!/bin/bash
# Startup script for DevOps AI Agent

echo "Starting DevOps AI Agent services..."

# Check if services are running
services=("node_exporter" "promtail" "devops-sample-app" "docker" "nginx")

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "✓ $service is running"
    else
        echo "✗ $service is not running, starting..."
        systemctl start "$service"
    fi
done

# Check Docker containers
if docker ps | grep -q cadvisor; then
    echo "✓ cAdvisor container is running"
else
    echo "✗ cAdvisor container not running, starting..."
    docker start cadvisor
fi

echo "DevOps AI Agent services check completed"
EOF

chmod +x /opt/devops-agent/scripts/startup.sh

# Create cron job for service monitoring
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/devops-agent/scripts/startup.sh >> /opt/devops-agent/logs/startup.log 2>&1") | crontab -

# Install additional monitoring tools
log "Installing additional monitoring tools..."
pip3 install \
    py-cpuinfo \
    GPUtil \
    speedtest-cli \
    netstat-nat \
    iotop \
    glances

# Create final status file
cat > /opt/devops-agent/logs/installation.log << EOF
Installation completed at: $(date)
Hostname: $(hostname)
IP Address: $(hostname -I)
Services installed:
- Docker: $(docker --version)
- Python: $(python3 --version)
- Node Exporter: Running on port 9100
- Promtail: Running on port 9080
- cAdvisor: Running on port 8080
- Sample App: Running on port 8501
- Nginx: Running on port 80
- CloudWatch Agent: Configured and running

Access URLs:
- Application: http://$(hostname -I | awk '{print $1}')
- Metrics: http://$(hostname -I | awk '{print $1}')/metrics
- Health: http://$(hostname -I | awk '{print $1}')/health
EOF

# Final system optimization
log "Performing final system optimization..."
# Increase file descriptor limits
echo "ubuntu soft nofile 65536" >> /etc/security/limits.conf
echo "ubuntu hard nofile 65536" >> /etc/security/limits.conf

# Optimize kernel parameters
cat >> /etc/sysctl.conf << EOF
# DevOps AI Agent optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

sysctl -p

log "Application server setup completed successfully!"
log "Services status:"
systemctl status node_exporter --no-pager
systemctl status promtail --no-pager
systemctl status devops-sample-app --no-pager
systemctl status docker --no-pager
systemctl status nginx --no-pager

# Send completion notification
wall "DevOps AI Agent application server setup completed at $(date)"
