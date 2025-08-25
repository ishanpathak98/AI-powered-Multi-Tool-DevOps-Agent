aws_region         = "ap-south-1"
ssh_allowed_cidr   = "192.168.1.111/32"  # <-- replace with your IPv4 + /32
public_key_openssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPzZkopOp6eR+HXqGXnre6FO41o+rwZYsd8bsQA8Ips pratap.bhanu3434@gmail.com"

project_name       = "AI-powered-Multi-Tool-DevOps-Agent"
instance_type      = "t2.micro"
root_volume_size   = 16
enable_ssm         = true
time_zone          = "Asia/Kolkata"

tags = {
  Environment = "dev"
  Owner       = "Ishan"
}
