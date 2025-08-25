variable "aws_region" {
  description = "AWS region (e.g., ap-south-1 for Mumbai)."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Human-friendly project name for tags/labels."
  type        = string
  default     = "AI-powered-Multi-Tool-DevOps-Agent"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet."
  type        = string
  default     = "10.10.1.0/24"
}

variable "ssh_allowed_cidr" {
  description = "Your IP in CIDR (e.g., 1.2.3.4/32) for SSH."
  type        = string
}

variable "public_key_openssh" {
  description = "Your SSH public key (OpenSSH format)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "root_volume_size" {
  description = "Root EBS size in GiB."
  type        = number
  default     = 16
}

variable "enable_ssm" {
  description = "Attach SSM instance profile for Session Manager."
  type        = bool
  default     = true
}

variable "time_zone" {
  description = "Instance timezone."
  type        = string
  default     = "Asia/Kolkata"
}

variable "tags" {
  description = "Additional tags for all resources."
  type        = map(string)
  default     = {}
}
