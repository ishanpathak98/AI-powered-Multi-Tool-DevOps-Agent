#!/bin/bash

# Variables substituted via Terraform templatefile()
NODE_EXPORTER_VERSION="${node_exporter_version}"
PROMTAIL_VERSION="${promtail_version}"
GRAFANA_ADMIN_PASSWORD="${grafana_password}"

# Update and install dependencies
apt-get update -y
apt-get install -y wget unzip curl apt-transport-https software-properties-common gnupg2

# -------------------------------
# Install Node Exporter
# -------------------------------
cd /opt
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
useradd -rs /bin/false node_exporter

cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# -------------------------------
# Install Promtail
# -------------------------------
cd /opt
wget https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
chmod a+x promtail-linux-amd64
mv promtail-linux-amd64 /usr/local/bin/promtail

cat <<EOF > /etc/promtail-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/syslog
EOF

cat <<EOF > /etc/systemd/system/promtail.service
[Unit]
Description=Promtail
After=network.target

[Service]
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail-config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable promtail
systemctl start promtail

# -------------------------------
# Install Grafana
# -------------------------------
wget -q -O - https://packages.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/grafana.gpg
add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
apt-get update -y
apt-get install -y grafana

systemctl enable grafana-server
systemctl start grafana-server

# Set admin password
grafana-cli admin reset-admin-password "${GRAFANA_ADMIN_PASSWORD}"
