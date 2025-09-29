output "web_security_group_id" {
  description = "ID of the web security group"
  value       = var.cloud_provider == "aws" ? aws_security_group.web[0].id : null
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = var.cloud_provider == "aws" ? aws_security_group.database[0].id : null
}

output "admin_security_group_id" {
  description = "ID of the admin security group"
  value       = var.cloud_provider == "aws" ? aws_security_group.admin[0].id : null
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = var.cloud_provider == "aws" ? aws_security_group.alb[0].id : null
}