output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_instance_ids" {
  value = module.ec2.instance_ids
}

output "ec2_instance_public_ips" {
  value = module.ec2.instance_public_ips
}

output "website_urls" {
  value = { for name, ip in module.ec2.instance_public_ips : name => "http://${ip}" }
}

