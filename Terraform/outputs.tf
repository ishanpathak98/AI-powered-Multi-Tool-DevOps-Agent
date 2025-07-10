output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "monitoring_server_public_ip" {
  description = "Public IP of the monitoring EC2 instance"
  value       = aws_instance.monitoring.public_ip
}

output "monitoring_server_private_ip" {
  description = "Private IP of the monitoring EC2 instance"
  value       = aws_instance.monitoring.private_ip
}

output "jenkins_server_public_ip" {
  description = "Public IP of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_server_private_ip" {
  description = "Private IP of the Jenkins server"
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

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_password
  sensitive   = true
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "application_url" {
  description = "URL to access Application"
  value       = "http://${aws_lb.app.dns_name}"
}

output "loki_url" {
  description = "URL to access Loki (Log aggregation)"
  value       = "http://${aws_instance.monitoring.private_ip}:3100"
}

output "ssh_command_monitoring" {
  description = "SSH command to connect to monitoring instance"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.monitoring.public_ip}"
}

output "ssh_command_jenkins" {
  description = "SSH command to connect to Jenkins instance"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.jenkins.public_ip}"
}
