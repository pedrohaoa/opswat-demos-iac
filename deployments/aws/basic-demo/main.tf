# Basic OPSWAT Demo Deployment on AWS
# This configuration deploys a simple OPSWAT demo environment

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
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "OPSWAT-Demos"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "Cybersecurity-Demo"
    }
  }
}

# Local variables
locals {
  common_tags = {
    Project     = "OPSWAT-Demos"
    Environment = var.environment
    Deployment  = "basic-demo"
  }
}

# Networking Module
module "networking" {
  source = "../../../modules/networking"

  cloud_provider     = "aws"
  environment        = var.environment
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  tags               = local.common_tags
}

# Security Module
module "security" {
  source = "../../../modules/security"

  cloud_provider      = "aws"
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  allowed_cidr_blocks = var.allowed_cidr_blocks
  tags                = local.common_tags
}

# Key Pair for EC2 instances
resource "aws_key_pair" "opswat_demo" {
  key_name   = "opswat-${var.environment}-key"
  public_key = var.public_key

  tags = local.common_tags
}

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template for OPSWAT MetaDefender Core
resource "aws_launch_template" "metadefender" {
  name_prefix   = "opswat-${var.environment}-metadefender-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.opswat_demo.key_name

  vpc_security_group_ids = [
    module.security.web_security_group_id,
    module.security.admin_security_group_id
  ]

  user_data = base64encode(templatefile("${path.module}/user-data/metadefender-setup.sh", {
    license_key = var.metadefender_license_key
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "opswat-${var.environment}-metadefender"
      Role = "MetaDefender-Core"
    })
  }

  tags = local.common_tags
}

# Auto Scaling Group for MetaDefender Core
resource "aws_autoscaling_group" "metadefender" {
  name                      = "opswat-${var.environment}-metadefender-asg"
  vpc_zone_identifier       = module.networking.public_subnet_ids
  target_group_arns         = [aws_lb_target_group.metadefender.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = 1
  max_size         = 3
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.metadefender.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "opswat-${var.environment}-metadefender-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Application Load Balancer
resource "aws_lb" "metadefender" {
  name               = "opswat-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security.alb_security_group_id]
  subnets            = module.networking.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(local.common_tags, {
    Name = "opswat-${var.environment}-alb"
  })
}

# Target Group for MetaDefender Core
resource "aws_lb_target_group" "metadefender" {
  name     = "opswat-${var.environment}-tg"
  port     = 8008
  protocol = "HTTP"
  vpc_id   = module.networking.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

# Load Balancer Listener
resource "aws_lb_listener" "metadefender" {
  load_balancer_arn = aws_lb.metadefender.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.metadefender.arn
  }
}