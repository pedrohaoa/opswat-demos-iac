# Example: Simple OPSWAT Demo using AWS modules
# This example shows how to use the networking and security modules
# to create a basic OPSWAT demonstration environment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Use the networking module
module "demo_network" {
  source = "../../modules/networking"
  
  cloud_provider     = "aws"
  environment        = "example"
  cidr_block         = "10.0.0.0/16"
  availability_zones = 2
  
  tags = {
    Project = "OPSWAT-Example"
    Owner   = "Demo-Team"
  }
}

# Use the security module
module "demo_security" {
  source = "../../modules/security"
  
  cloud_provider      = "aws"
  environment         = "example"
  vpc_id             = module.demo_network.vpc_id
  allowed_cidr_blocks = ["10.0.0.0/8"]  # Only allow internal traffic
  
  tags = {
    Project = "OPSWAT-Example"
    Owner   = "Demo-Team"
  }
}

# Simple EC2 instance for MetaDefender Core
resource "aws_instance" "metadefender" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  
  subnet_id              = module.demo_network.public_subnet_ids[0]
  vpc_security_group_ids = [module.demo_security.web_security_group_id]
  
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              
              # Run MetaDefender Core container
              docker run -d \
                --name metadefender-core \
                -p 8008:8008 \
                -p 8009:8009 \
                --restart unless-stopped \
                opswat/metadefender:latest
              EOF
  )
  
  tags = {
    Name    = "opswat-example-metadefender"
    Project = "OPSWAT-Example"
  }
}

# Data source for Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.demo_network.vpc_id
}

output "metadefender_public_ip" {
  description = "Public IP of MetaDefender instance"
  value       = aws_instance.metadefender.public_ip
}

output "metadefender_url" {
  description = "URL to access MetaDefender Core"
  value       = "http://${aws_instance.metadefender.public_ip}:8008"
}