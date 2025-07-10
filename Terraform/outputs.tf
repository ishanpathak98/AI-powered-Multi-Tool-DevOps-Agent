output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "monitoring_server_public_ip" {
  description = "Public IP of the monitoring server"
  value       = aws_instance.monitoring.public_ip
}

output "monitoring_server_private_ip" {
  description = "Private IP of the monitoring server"
  value       = aws_instance.monitoring.private_ip
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = random_password.grafana_admin.result
  sensitive   = true
}

output "grafana_url" {
  description = "Grafana web interface"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus web interface"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "loki_url" {
  description = "Loki log aggregator interface"
  value       = "http://${aws_instance.monitoring.private_ip}:3100"
}

output "ssh_command_monitoring" {
  description = "SSH command to connect to monitoring instance"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.monitoring.public_ip}"
}
