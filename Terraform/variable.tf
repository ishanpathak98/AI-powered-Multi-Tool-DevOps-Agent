# terraform/variables.tf

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "devops-ai-agent"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.micro"
}

variable "monitoring_instance_type" {
  description = "EC2 instance type for monitoring server"
  type        = string
  default     = "t3.small"
}

variable "email_domain" {
  description = "Domain for SES email notifications"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API key for LLM analysis"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cpu_threshold" {
  description = "CPU usage threshold for alerts (percentage)"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Memory usage threshold for alerts (percentage)"
  type        = number
  default     = 85
}

variable "disk_threshold" {
  description = "Disk usage threshold for alerts (percentage)"
  type        = number
  default     = 90
}

variable "alert_duration" {
  description = "Duration in seconds before triggering alert"
  type        = number
  default     = 120
}

variable "enable_auto_remediation" {
  description = "Enable automatic remediation actions"
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email address for notifications"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access monitoring interfaces"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 7
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "auto_scaling_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "auto_scaling_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "auto_scaling_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "enable_ssl" {
  description = "Enable SSL/TLS for web interfaces"
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS"
  type        = string
  default     = ""
}

variable "enable_prometheus_remote_write" {
  description = "Enable Prometheus remote write to CloudWatch"
  type        = bool
  default     = false
}

variable "grafana_version" {
  description = "Grafana version to install"
  type        = string
  default     = "latest"
}

variable "prometheus_version" {
  description = "Prometheus version to install"
  type        = string
  default     = "latest"
}

variable "loki_version" {
  description = "Loki version to install"
  type        = string
  default     = "latest"
}

variable "jenkins_version" {
  description = "Jenkins version to install"
  type        = string
  default     = "lts"
}

variable "docker_version" {
  description = "Docker version to install"
  type        = string
  default     = "latest"
}

variable "python_version" {
  description = "Python version to install"
  type        = string
  default     = "3.9"
}

variable "node_exporter_version" {
  description = "Node Exporter version to install"
  type        = string
  default     = "latest"
}

variable "cadvisor_version" {
  description = "cAdvisor version to install"
  type        = string
  default     = "latest"
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Cron schedule for backups"
  type        = string
  default     = "0 2 * * *"
}

variable "enable_monitoring_alerts" {
  description = "Enable monitoring alerts"
  type        = bool
  default     = true
}

variable "alert_manager_config" {
  description = "Alert Manager configuration"
  type        = string
  default     = ""
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "7d"
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "enable_security_scanning" {
  description = "Enable security scanning for containers"
  type        = bool
  default     = true
}

variable "container_registry" {
  description = "Container registry URL"
  type        = string
  default     = "docker.io"
}

variable "enable_chaos_engineering" {
  description = "Enable chaos engineering tools"
  type        = bool
  default     = false
}

variable "chaos_monkey_schedule" {
  description = "Schedule for chaos monkey experiments"
  type        = string
  default     = "0 10 * * 1-5"
}

variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

variable "spot_instance_enabled" {
  description = "Enable spot instances for cost optimization"
  type        = bool
  default     = false
}

variable "spot_max_price" {
  description = "Maximum price for spot instances"
  type        = string
  default     = "0.05"
}

variable "enable_multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = ""
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for audit logging"
  type        = bool
  default     = false
}

variable "enable_config" {
  description = "Enable AWS Config for compliance"
  type        = bool
  default     = false
}

variable "enable_guardduty" {
  description = "Enable GuardDuty for threat detection"
  type        = bool
  default     = false
}

variable "enable_secrets_manager" {
  description = "Enable AWS Secrets Manager for secret storage"
  type        = bool
  default     = true
}

variable "enable_parameter_store" {
  description = "Enable AWS Systems Manager Parameter Store"
  type        = bool
  default     = true
}

variable "enable_xray" {
  description = "Enable AWS X-Ray for distributed tracing"
  type        = bool
  default     = false
}

variable "enable_service_discovery" {
  description = "Enable AWS Cloud Map for service discovery"
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Enable Container Insights for EKS/ECS"
  type        = bool
  default     = false
}

variable "enable_application_insights" {
  description = "Enable Application Insights"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
