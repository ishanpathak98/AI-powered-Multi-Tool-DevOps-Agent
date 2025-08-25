locals {
  # Turn the project name into a safe slug for AWS names (lowercase + dashes)
  project_slug = lower(replace(replace(var.project_name, " ", "-"), "_", "-"))

  common_tags = merge({
    Project   = var.project_name
    ProjectId = local.project_slug
    ManagedBy = "Terraform"
  }, var.tags)
}

# ----- Ubuntu 22.04 (Jammy) AMI -----
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ----- Networking: VPC + Subnet + IGW + Route -----
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.common_tags, { Name = "${local.project_slug}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${local.project_slug}-igw" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  tags                    = merge(local.common_tags, { Name = "${local.project_slug}-public-subnet" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${local.project_slug}-public-rt" })
}

resource "aws_route" "default_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on             = [aws_internet_gateway.igw]
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ----- Security Group: SSH only from your IP -----
resource "aws_security_group" "ec2_sg" {
  name        = "${local.project_slug}-ec2-sg"
  description = "Allow SSH from your IP only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.project_slug}-ec2-sg" })
}

# ----- Key Pair from your public key -----
resource "aws_key_pair" "this" {
  key_name   = "${local.project_slug}-key"
  public_key = var.public_key_openssh
  tags       = local.common_tags
}

# ----- (Optional) SSM Instance Profile -----
resource "aws_iam_role" "ssm" {
  count = var.enable_ssm ? 1 : 0
  name  = "${local.project_slug}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { "Service": "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  count = var.enable_ssm ? 1 : 0
  name  = "${local.project_slug}-ssm-profile"
  role  = aws_iam_role.ssm[0].name
  tags  = local.common_tags
}

# ----- EC2 Instance (Ubuntu 22.04) -----
resource "aws_instance" "opsbot" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true

  # Built-in templatefile() avoids extra providers
  user_data = templatefile("${path.module}/user_data.sh.tmpl", {
    time_zone = var.time_zone
    project   = var.project_name
    slug      = local.project_slug
  })

  iam_instance_profile = var.enable_ssm ? aws_iam_instance_profile.ssm[0].name : null

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(local.common_tags, { Name = "${local.project_slug}-ec2" })
}
