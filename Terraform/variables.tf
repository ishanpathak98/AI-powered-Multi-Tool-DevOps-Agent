variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project identifier prefix"
  type        = string
  default     = "devops-ai-agent"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "node_exporter_version" {
  description = "Version of Prometheus Node Exporter to install"
  type        = string
  default     = "1.8.1"
}

variable "promtail_version" {
  description = "Version of Promtail to install"
  type        = string
  default     = "2.9.4"
}

variable "grafana_password" {
  description = "Grafana admin password"
  type        = string
  default     = "admin123"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair to use for EC2 access"
  type        = string
  default     = "devops-ai-agent-key"
}
