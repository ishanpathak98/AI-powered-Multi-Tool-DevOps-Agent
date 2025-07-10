# terraform/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "DevOps-AI-Agent"
      Environment = var.environment
      Owner       = "MLOps-Team"
      Terraform   = "true"
    }
  }
}

# Data resource for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Generate SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "devops_agent_key" {
  key_name   = "devops-agent-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/devops-agent-key.pem"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-${count.index}"
  }
}

# Security Group for App
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Security group for app"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role and Profile
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Monitoring EC2 Instance
resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  key_name                    = aws_key_pair.devops_agent_key.key_name
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

  tags = {
    Name = "Monitoring"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "devops_agent" {
  name              = "/devops/agent/logs"
  retention_in_days = 7
}

# Launch Template for Auto Scaling
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.devops_agent_key.key_name

  vpc_security_group_ids = [aws_security_group.app.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/scripts/app_userdata.sh", {
    prometheus_server       = aws_instance.monitoring.private_ip,
    loki_server             = aws_instance.monitoring.private_ip,
    cloudwatch_log_group    = aws_cloudwatch_log_group.devops_agent.name,
    project_name            = var.project_name,
    node_exporter_version   = var.node_exporter_version,
    promtail_version        = var.promtail_version
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app"
      Type = "application"
    }
  }
}

# Add this to your variables.tf if not already present:
#
# variable "node_exporter_version" {
#   description = "Prometheus Node Exporter version"
#   type        = string
#   default     = "1.8.1"
# }
#
# variable "promtail_version" {
#   description = "Grafana Promtail version"
#   type        = string
#   default     = "2.9.4"
# }
