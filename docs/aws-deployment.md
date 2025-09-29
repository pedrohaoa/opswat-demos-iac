# AWS Deployment Guide

This guide walks you through deploying OPSWAT MetaDefender Core on AWS using Terraform.

## Architecture Overview

The AWS deployment creates:

- **VPC**: Isolated network with public and private subnets across multiple AZs
- **Application Load Balancer**: Distributes traffic to MetaDefender Core instances
- **Auto Scaling Group**: Ensures high availability and scalability
- **Security Groups**: Restrict access to only necessary ports
- **CloudWatch**: Monitoring and logging for the infrastructure

## Prerequisites

### 1. AWS Account Setup

- AWS account with appropriate permissions
- AWS CLI installed and configured
- Access key and secret key with permissions to create VPC, EC2, ALB, and IAM resources

### 2. Local Tools

- Terraform >= 1.0
- AWS CLI
- SSH key pair for EC2 access

### 3. OPSWAT License

- Valid MetaDefender Core license key (contact OPSWAT sales)

## Step-by-Step Deployment

### 1. Clone the Repository

```bash
git clone https://github.com/pedrohaoa/opswat-demos-iac.git
cd opswat-demos-iac
```

### 2. Configure AWS CLI

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-west-2)
- Default output format (json)

### 3. Generate SSH Key Pair

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/opswat-demo
```

### 4. Configure Deployment Variables

```bash
cd deployments/aws/basic-demo
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "us-west-2"
environment = "demo"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = 2

# Security Configuration
allowed_cidr_blocks = ["YOUR_IP/32"]  # Replace with your IP

# EC2 Configuration
public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-public-key-content"
instance_type = "t3.medium"
desired_capacity = 1

# OPSWAT Configuration
metadefender_license_key = "your-license-key-here"
```

### 5. Deploy the Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 6. Access Your Deployment

After deployment completes, Terraform will output the access URLs:

```
load_balancer_url = "http://opswat-demo-alb-123456789.us-west-2.elb.amazonaws.com"
metadefender_management_url = "http://opswat-demo-alb-123456789.us-west-2.elb.amazonaws.com:8008"
```

- **Application URL**: Access the main MetaDefender interface
- **Management URL**: Access the MetaDefender management console

## Configuration Options

### Instance Types

| Instance Type | vCPU | Memory | Use Case |
|---------------|------|---------|----------|
| t3.medium     | 2    | 4 GB    | Small demos |
| t3.large      | 2    | 8 GB    | Medium demos |
| c5.large      | 2    | 4 GB    | CPU-intensive scanning |
| c5.xlarge     | 4    | 8 GB    | High-performance demos |

### Scaling Configuration

- **Min Size**: 1 instance (always running)
- **Max Size**: 3 instances (for high load)
- **Desired Capacity**: Configurable via `desired_capacity` variable

### Security Groups

- **Web Security Group**: Ports 80, 443, 8008
- **Admin Security Group**: Ports 22 (SSH), 3389 (RDP)
- **Database Security Group**: Ports 3306 (MySQL), 5432 (PostgreSQL)
- **ALB Security Group**: Ports 80, 443

## Monitoring and Logging

### CloudWatch Metrics

The deployment automatically configures CloudWatch monitoring for:

- CPU utilization
- Memory usage
- Disk usage
- Network metrics

### Log Groups

- `/aws/ec2/opswat/metadefender`: Application logs
- `/aws/applicationloadbalancer/`: ALB access logs

### Alarms

Set up CloudWatch alarms for:

```bash
# High CPU utilization
aws cloudwatch put-metric-alarm \
  --alarm-name "OPSWAT-HighCPU" \
  --alarm-description "High CPU utilization" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold

# High memory utilization
aws cloudwatch put-metric-alarm \
  --alarm-name "OPSWAT-HighMemory" \
  --alarm-description "High memory utilization" \
  --metric-name MemoryUtilization \
  --namespace OPSWAT/MetaDefender \
  --statistic Average \
  --period 300 \
  --threshold 85 \
  --comparison-operator GreaterThanThreshold
```

## Troubleshooting

### Common Issues

#### 1. Terraform Authentication Error

```
Error: Error configuring the backend "s3": NoCredentialsProvided
```

**Solution**: Configure AWS CLI or set environment variables:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

#### 2. Instance Launch Failure

**Symptoms**: Auto Scaling Group shows instances in "Unhealthy" state

**Solution**: Check user data script logs:
```bash
ssh -i ~/.ssh/opswat-demo ec2-user@INSTANCE_IP
sudo cat /var/log/cloud-init-output.log
```

#### 3. MetaDefender Not Accessible

**Symptoms**: Load balancer returns 503 errors

**Solution**: 
1. Check security groups allow traffic on port 8008
2. Verify MetaDefender container is running:
```bash
ssh -i ~/.ssh/opswat-demo ec2-user@INSTANCE_IP
docker ps
docker logs metadefender-core
```

#### 4. License Key Issues

**Symptoms**: MetaDefender shows license errors

**Solution**: 
1. Verify license key is valid
2. Check license key format in terraform.tfvars
3. Restart MetaDefender container:
```bash
cd /opt/opswat
sudo docker-compose restart
```

### Getting Instance IPs

```bash
# List all instances in the Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "opswat-demo-metadefender-asg" \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
  --output table

# Get public IP of an instance
aws ec2 describe-instances \
  --instance-ids "i-1234567890abcdef0" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

## Security Considerations

### Network Security

- All instances are in private subnets by default
- Only load balancer is in public subnets
- Security groups follow principle of least privilege

### Access Control

- SSH access restricted to specified CIDR blocks
- Management interface access controlled via security groups
- Use IAM roles for EC2 instances (avoid hardcoded credentials)

### Data Protection

- Enable EBS encryption for instance storage
- Use SSL/TLS for all web traffic
- Regularly update and patch instances

## Cost Optimization

### Resource Tagging

All resources are tagged for cost tracking:
- Project: OPSWAT-Demos
- Environment: demo/staging/prod
- ManagedBy: Terraform

### Auto Scaling

- Scale down during off-hours
- Use spot instances for non-production environments
- Monitor CloudWatch metrics to optimize instance types

### Clean Up

```bash
# Destroy all resources when done
terraform destroy
```

## Next Steps

After successful deployment:

1. Configure MetaDefender scanning engines
2. Set up SSL certificates for HTTPS
3. Configure backup and disaster recovery
4. Implement CI/CD pipeline for updates
5. Set up monitoring dashboards