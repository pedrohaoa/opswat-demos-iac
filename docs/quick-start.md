# OPSWAT IaC Quick Start Guide

Get your OPSWAT demonstration environment running in minutes!

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- Cloud provider account (AWS, Azure, or GCP)
- Cloud provider CLI tool configured
- SSH key pair

## 🚀 Quick AWS Deployment (5 minutes)

### 1. Clone the Repository
```bash
git clone https://github.com/pedrohaoa/opswat-demos-iac.git
cd opswat-demos-iac
```

### 2. Configure AWS Credentials
```bash
aws configure
# Enter your Access Key ID, Secret Access Key, and preferred region
```

### 3. Generate SSH Key Pair
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/opswat-demo
# Press Enter to accept defaults
```

### 4. Configure Deployment
```bash
cd deployments/aws/basic-demo
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your settings:
# - Replace public_key with content of ~/.ssh/opswat-demo.pub
# - Set your preferred AWS region
# - Configure allowed_cidr_blocks (restrict to your IP for security)
```

### 5. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy (takes 5-10 minutes)
terraform apply
```

### 6. Access Your Deployment
After deployment completes, you'll see outputs like:
```
load_balancer_url = "http://opswat-demo-alb-123456789.us-west-2.elb.amazonaws.com"
metadefender_management_url = "http://opswat-demo-alb-123456789.us-west-2.elb.amazonaws.com:8008"
```

🎉 **That's it!** Access MetaDefender Core at the provided URL.

## 🔧 Quick Azure Deployment

### 1. Configure Azure CLI
```bash
az login
az account set --subscription "Your Subscription Name"
```

### 2. Deploy to Azure
```bash
cd deployments/azure/basic-demo
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Azure settings

terraform init
terraform plan
terraform apply
```

## 📊 What Gets Deployed

### AWS Deployment
- **VPC** with public/private subnets across 2 AZs
- **Application Load Balancer** for high availability
- **Auto Scaling Group** with MetaDefender Core instances
- **Security Groups** with minimal required access
- **CloudWatch** monitoring and logging

### Azure Deployment
- **Resource Group** for organizing resources
- **Virtual Network** with application and gateway subnets
- **Application Gateway** for load balancing
- **Virtual Machine Scale Set** running MetaDefender Core
- **Network Security Groups** for access control

## 🔒 Security Features

- **Network Isolation**: Resources deployed in private subnets where possible
- **Least Privilege**: Security groups only allow necessary traffic
- **Encryption**: Storage and data in transit encrypted
- **Monitoring**: CloudWatch/Azure Monitor enabled for all resources

## 💰 Cost Optimization

The default deployment uses cost-optimized instance types:
- **AWS**: t3.medium instances (~$30/month per instance)
- **Azure**: Standard_B2s instances (~$31/month per instance)

### Auto-scaling saves costs:
- Scales down during low usage
- Scales up during demonstrations
- Automatic cleanup with `terraform destroy`

## 🛠️ Common Customizations

### Change Instance Size
```hcl
# In terraform.tfvars
instance_type = "t3.large"  # AWS
vm_size = "Standard_B4s"    # Azure
```

### Add HTTPS/SSL
```hcl
# Add SSL certificate ARN (AWS) or Key Vault certificate (Azure)
ssl_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

### Scale for Production
```hcl
# Increase capacity for larger demos
desired_capacity = 3  # AWS
vm_instances = 3      # Azure
```

## 🔍 Troubleshooting

### Access Issues
```bash
# Check security groups allow your IP
curl -v http://YOUR_LOAD_BALANCER_URL

# SSH to instance to check logs
ssh -i ~/.ssh/opswat-demo ec2-user@INSTANCE_IP
sudo docker logs metadefender-core
```

### MetaDefender Not Starting
1. Check license key in terraform.tfvars
2. Verify container logs:
   ```bash
   ssh -i ~/.ssh/opswat-demo ec2-user@INSTANCE_IP
   cd /opt/opswat
   sudo docker-compose logs
   ```

### Cost Concerns
```bash
# Always destroy when done with demos
terraform destroy

# Monitor costs in AWS Cost Explorer or Azure Cost Management
```

## 📚 Next Steps

1. **Configure MetaDefender**: Set up scanning engines and policies
2. **Add SSL Certificate**: Enable HTTPS for production use
3. **Setup Monitoring**: Configure alerts and dashboards
4. **Backup Strategy**: Implement automated backups
5. **CI/CD Pipeline**: Automate deployments with GitHub Actions

## 🆘 Getting Help

- **Documentation**: Check the `docs/` directory for detailed guides
- **Issues**: Create GitHub issues for bugs or feature requests
- **OPSWAT Support**: Contact OPSWAT for MetaDefender-specific questions
- **Community**: Join OPSWAT community forums

## 🧹 Cleanup

**Important**: Always clean up resources when done:

```bash
terraform destroy
```

This removes all created resources and stops billing.

---

⭐ **Pro Tip**: Bookmark this repository and star it for quick access to OPSWAT IaC templates!