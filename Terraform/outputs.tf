output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.opsbot.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.opsbot.public_dns
}

output "ssh_command" {
  description = "Copy/paste SSH command (replace with your private key path)"
  value       = "ssh -i ./YOUR_PRIVATE_KEY.pem ubuntu@${aws_instance.opsbot.public_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public.id
}
