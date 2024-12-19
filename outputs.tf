output "instance_ips" {
  value       = aws_instance.devops_instance[*].public_ip
  description = "Public IPs of the EC2 instances"
}

output "ssh_key_name" {
  value       = aws_key_pair.devops_key.key_name
  description = "Name of the SSH key associated with the EC2 instances"
}
