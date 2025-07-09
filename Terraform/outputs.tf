# terraform/outputs.tf

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "monitoring_server_public_ip" {
  description = "Public IP address of the monitoring server"
  value       = aws_instance.monitoring.public_ip
}

output "monitoring_server_private_ip" {
  description = "Private IP address of the monitoring server"
  value       = aws_instance.monitoring.private_ip
}

output "jenkins_server_public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_server_private_ip" {
  description = "Private IP address of the Jenkins server"
  value       = aws_instance.jenkins.private_ip
}

output "application_load_balancer_dns" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.app.dns_name
}

output "application_load_balancer_zone_id" {
  description = "Zone ID of the application load balancer"
  value       = aws_lb.app.zone_id
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = random_password.grafana_
