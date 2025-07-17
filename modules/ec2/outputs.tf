
output "instance_ids" {
  value = { for name, instance in aws_instance.app : name => instance.id }
}

output "instance_public_ips" {
  value = { for name, instance in aws_instance.app : name => instance.public_ip }
}

