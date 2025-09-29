# Networking Module for OPSWAT Demos
# Supports multi-cloud deployment with provider-specific resources

variable "cloud_provider" {
  description = "Cloud provider (aws, azure, gcp)"
  type        = string
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be one of: aws, azure, gcp."
  }
}

variable "environment" {
  description = "Environment name (demo, pov, staging, prod)"
  type        = string
  default     = "demo"
}

variable "cidr_block" {
  description = "CIDR block for the network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "OPSWAT-Demos"
    Purpose = "Cybersecurity-Demo"
  }
}

# AWS VPC
resource "aws_vpc" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0

  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-igw"
  })
}

data "aws_availability_zones" "available" {
  count = var.cloud_provider == "aws" ? 1 : 0
  state = "available"
}

resource "aws_subnet" "public" {
  count = var.cloud_provider == "aws" ? var.availability_zones : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available[0].names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-public-${count.index + 1}"
    Type = "Public"
  })
}

resource "aws_subnet" "private" {
  count = var.cloud_provider == "aws" ? var.availability_zones : 0

  vpc_id            = aws_vpc.main[0].id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available[0].names[count.index]

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-private-${count.index + 1}"
    Type = "Private"
  })
}

resource "aws_route_table" "public" {
  count = var.cloud_provider == "aws" ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = var.cloud_provider == "aws" ? var.availability_zones : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# NAT Gateway for private subnets
resource "aws_eip" "nat" {
  count = var.cloud_provider == "aws" ? var.availability_zones : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count = var.cloud_provider == "aws" ? var.availability_zones : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-nat-${count.index + 1}"
  })
}

resource "aws_route_table" "private" {
  count = var.cloud_provider == "aws" ? var.availability_zones : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = "opswat-${var.environment}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private" {
  count = var.cloud_provider == "aws" ? var.availability_zones : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}