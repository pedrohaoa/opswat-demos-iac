# Security Module for OPSWAT Demos
# Implements security groups and access controls for cybersecurity demonstrations

variable "cloud_provider" {
  description = "Cloud provider (aws, azure, gcp)"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed for administrative access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Web Application Security Group
resource "aws_security_group" "web" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name_prefix = "opswat-${var.environment}-web-"
  vpc_id      = var.vpc_id
  description = "Security group for OPSWAT web applications"

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MetaDefender Core default port
  ingress {
    description = "MetaDefender Core"
    from_port   = 8008
    to_port     = 8008
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-web"
    Type = "Web"
  })
}

# Database Security Group
resource "aws_security_group" "database" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name_prefix = "opswat-${var.environment}-db-"
  vpc_id      = var.vpc_id
  description = "Security group for OPSWAT databases"

  # MySQL/MariaDB
  ingress {
    description     = "MySQL/MariaDB"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web[0].id]
  }

  # PostgreSQL
  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web[0].id]
  }

  # Redis
  ingress {
    description     = "Redis"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.web[0].id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-database"
    Type = "Database"
  })
}

# SSH/RDP Access Security Group
resource "aws_security_group" "admin" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name_prefix = "opswat-${var.environment}-admin-"
  vpc_id      = var.vpc_id
  description = "Security group for administrative access"

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # RDP access
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # WinRM HTTPS
  ingress {
    description = "WinRM HTTPS"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-admin"
    Type = "Administrative"
  })
}

# Load Balancer Security Group
resource "aws_security_group" "alb" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name_prefix = "opswat-${var.environment}-alb-"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load Balancer"

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-alb"
    Type = "LoadBalancer"
  })
}