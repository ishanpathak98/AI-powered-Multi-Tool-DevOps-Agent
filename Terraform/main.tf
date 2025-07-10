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
    prometheus_server       = aws_instance.monitoring.private_ip
    loki_server             = aws_instance.monitoring.private_ip
    cloudwatch_log_group    = aws_cloudwatch_log_group.devops_agent.name
    project_name            = var.project_name
    node_exporter_version   = var.node_exporter_version
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
