output "vpc_id" {
  description = "ID of the VPC"
  value       = var.cloud_provider == "aws" ? aws_vpc.main[0].id : null
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = var.cloud_provider == "aws" ? aws_vpc.main[0].cidr_block : null
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = var.cloud_provider == "aws" ? aws_subnet.public[*].id : []
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = var.cloud_provider == "aws" ? aws_subnet.private[*].id : []
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = var.cloud_provider == "aws" ? aws_internet_gateway.main[0].id : null
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = var.cloud_provider == "aws" ? aws_nat_gateway.main[*].id : []
}