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
  value       = random_password.grafana_admin.result
  sensitive   = true
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "loki_url" {
  description = "URL to access Loki"
  value       = "http://${aws_instance.monitoring.private_ip}:3100"
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.app.dns_name}"
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.devops_agent.name
}

output "key_pair_name" {
  description = "Name of the key pair for SSH access"
  value       = aws_key_pair.devops_agent_key.key_name
}

output "private_key_path" {
  description = "Path to the private key file"
  value       = local_file.private_key.filename
}

output "security_group_monitoring_id" {
  description = "ID of the monitoring security group"
  value       = aws_security_group.monitoring.id
}

output "security_group_app_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "security_group_jenkins_id" {
  description = "ID of the Jenkins security group"
  value       = aws_security_group.jenkins.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app.id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_role.arn
}

output "nat_gateway_ip" {
  description = "Public IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# SSH Connection Commands
output "ssh_command_monitoring" {
  description = "SSH command to connect to monitoring server"
  value       = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.monitoring.public_ip}"
}

output "ssh_command_jenkins" {
  description = "SSH command to connect to Jenkins server"
  value       = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.jenkins.public_ip}"
}

# Quick Access URLs
output "quick_access_urls" {
  description = "Quick access URLs for all services"
  value = {
    prometheus = "http://${aws_instance.monitoring.public_ip}:9090"
    grafana    = "http://${aws_instance.monitoring.public_ip}:3000"
    jenkins    = "http://${aws_instance.jenkins.public_ip}:8080"
    application = "http://${aws_lb.app.dns_name}"
    loki       = "http://${aws_instance.monitoring.private_ip}:3100"
  }
}

# Configuration Information
output "configuration_info" {
  description = "Important configuration information"
  value = {
    grafana_admin_user     = var.grafana_admin_user
    grafana_admin_password = random_password.grafana_admin.result
    aws_region            = var.aws_region
    environment           = var.environment
    project_name          = var.project_name
    vpc_cidr              = var.vpc_cidr
    cpu_threshold         = var.cpu_threshold
    memory_threshold      = var.memory_threshold
    disk_threshold        = var.disk_threshold
  }
  sensitive = true
}
