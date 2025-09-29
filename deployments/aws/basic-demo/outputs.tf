output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.metadefender.dns_name
}

output "load_balancer_url" {
  description = "URL to access MetaDefender Core"
  value       = "http://${aws_lb.metadefender.dns_name}"
}

output "metadefender_management_url" {
  description = "MetaDefender Core management interface URL"
  value       = "http://${aws_lb.metadefender.dns_name}:8008"
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    web      = module.security.web_security_group_id
    admin    = module.security.admin_security_group_id
    database = module.security.database_security_group_id
    alb      = module.security.alb_security_group_id
  }
}