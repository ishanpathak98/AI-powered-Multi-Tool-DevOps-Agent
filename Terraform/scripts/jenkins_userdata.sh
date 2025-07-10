#!/bin/bash
# terraform/scripts/jenkins_userdata.sh

set -e

# Log everything
exec > >(tee /var/log/jenkins-userdata.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Updating system..."
apt-get update -y && apt-get upgrade -y

echo "Installing Java (required for Jenkins)..."
apt-get install -y openjdk-11-jdk

echo "Adding Jenkins repo and installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins

echo "Starting and enabling Jenkins service..."
systemctl enable jenkins
systemctl start jenkins

echo "Opening firewall for Jenkins (port 8080)..."
ufw allow 8080
ufw --force enable

echo "Jenkins installed successfully. Access it on port 8080."
