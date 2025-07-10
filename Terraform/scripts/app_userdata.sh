#!/bin/bash

# Exit on any error
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting user data script execution..."

# Update system
echo "Updating system packages..."
yum update -y

# Install essential packages
echo "Installing essential packages..."
yum install -y wget curl unzip docker aws-cli

# Start and enable Docker
echo "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
echo "Creating application directory..."
mkdir -p /opt/app
cd /opt/app

# Install CloudWatch agent
echo "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
echo "Configuring CloudWatch agent..."
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/var/log/messages"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/user-data"
          },
          {
            "file_path": "/opt/app/app.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/app"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "${project_name}/EC2",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "diskio": {
        "measurement": [
          "io_time"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch agent
echo "Starting CloudWatch agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Install Node Exporter for Prometheus monitoring
echo "Installing Node Exporter..."
NODE_EXPORTER_VERSION="${NODE_EXPORTER_VERSION}"
wget https://github.com/prometheus/node_exporter/releases/download/v"$NODE_EXPORTER_VERSION"/node_exporter-"$NODE_EXPORTER_VERSION".linux-amd64.tar.gz
mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64*

# Create node_exporter user
useradd --no-create-home --shell /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create systemd service for Node Exporter
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

# Start and enable Node Exporter
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

# Configure Promtail for Loki
echo "Installing Promtail..."
wget https://github.com/grafana/loki/releases/latest/download/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
mv promtail-linux-amd64 /usr/local/bin/promtail
chmod +x /usr/local/bin/promtail

# Create promtail user
useradd --no-create-home --shell /bin/false promtail
mkdir -p /etc/promtail
chown promtail:promtail /etc/promtail

# Create Promtail configuration
cat > /etc/promtail/promtail.yml << EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://${loki_server}:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log
          instance: \$(hostname)
          project: ${project_name}
  
  - job_name: app
    static_configs:
      - targets:
          - localhost
        labels:
          job: app
          __path__: /opt/app/*log
          instance: \$(hostname)
          project: ${project_name}
EOF

# Create systemd service for Promtail
cat > /etc/systemd/system/promtail.service << 'EOF'
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=promtail
Group=promtail
ExecStart=/usr/local/bin/promtail -config.file /etc/promtail/promtail.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Promtail
systemctl daemon-reload
systemctl start promtail
systemctl enable promtail

# Create sample application
echo "Creating sample application..."
cat > /opt/app/app.py << 'EOF'
#!/usr/bin/env python3
import time
import logging
from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import random

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/opt/app/app.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total app requests', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('app_request_duration_seconds', 'Request latency')

@app.route('/')
def hello():
    REQUEST_COUNT.labels(method='GET', endpoint='/').inc()
    with REQUEST_LATENCY.time():
        time.sleep(random.uniform(0.1, 0.5))  # Simulate work
        logger.info("Hello endpoint accessed")
        return jsonify({"message": "Hello from ${project_name}!", "status": "healthy"})

@app.route('/health')
def health():
    REQUEST_COUNT.labels(method='GET', endpoint='/health').inc()
    with REQUEST_LATENCY.time():
        logger.info("Health check endpoint accessed")
        return jsonify({"status": "healthy", "timestamp": time.time()})

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    logger.info("Starting application...")
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# Create requirements.txt
cat > /opt/app/requirements.txt << 'EOF'
Flask==2.3.3
prometheus_client==0.17.1
EOF

# Install Python and pip
echo "Installing Python and dependencies..."
yum install -y python3 python3-pip
pip3 install -r /opt/app/requirements.txt

# Create systemd service for the app
cat > /etc/systemd/system/app.service << 'EOF'
[Unit]
Description=Sample Application
After=network.target

[Service]
Type=simple
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/app
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chown -R ec2-user:ec2-user /opt/app
chmod +x /opt/app/app.py

# Start and enable the application
systemctl daemon-reload
systemctl start app
systemctl enable app

# Create a startup script for container orchestration if needed
cat > /opt/app/docker-compose.yml << 'EOF'
version: '3.8'
services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      - PROJECT_NAME=${project_name}
      - PROMETHEUS_SERVER=${prometheus_server}
      - LOKI_SERVER=${loki_server}
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
EOF

# Create Dockerfile
cat > /opt/app/Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
EOF

# Wait for services to start
echo "Waiting for services to start..."
sleep 10

# Verify services are running
echo "Checking service status..."
systemctl status node_exporter --no-pager
systemctl status promtail --no-pager
systemctl status app --no-pager

echo "User data script completed successfully!"
echo "Services status:"
echo "- Node Exporter: http://localhost:9100"
echo "- Application: http://localhost:5000"
echo "- Promtail: running on port 9080"
echo "- Prometheus server: ${prometheus_server}"
echo "- Loki server: ${loki_server}"
echo "- CloudWatch log group: ${cloudwatch_log_group}"
echo "- Project: ${project_name}"
