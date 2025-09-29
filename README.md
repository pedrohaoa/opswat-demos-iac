# OPSWAT Demos - Infrastructure as Code

Secure repository for deploying OPSWAT demonstration environments and Proof of Concepts (PoVs).

## Overview

This repository contains Infrastructure as Code (IaC) templates and configurations for deploying OPSWAT cybersecurity solutions in cloud environments for demonstrations, testing, and proof of concept scenarios.

## Features

- **Multi-Cloud Support**: Deploy on AWS, Azure, and GCP
- **Security-First**: All deployments follow cybersecurity best practices
- **Automated Deployment**: One-click deployment for demo environments
- **Scalable Architecture**: Support for small demos to enterprise PoVs
- **Cost Optimized**: Automated resource cleanup and cost monitoring

## Supported OPSWAT Products

- MetaDefender Core
- MetaDefender Cloud
- MetaDefender Drive
- OESIS Framework
- AppRemover

## Quick Start

### Prerequisites

- Terraform >= 1.0
- Cloud provider CLI tools (AWS CLI, Azure CLI, or gcloud)
- Valid cloud provider account with appropriate permissions

### Deployment

1. Clone this repository:
   ```bash
   git clone https://github.com/pedrohaoa/opswat-demos-iac.git
   cd opswat-demos-iac
   ```

2. Choose your deployment scenario:
   ```bash
   cd deployments/aws/basic-demo
   # or
   cd deployments/azure/enterprise-pov
   # or
   cd deployments/gcp/metadefender-core
   ```

3. Configure your environment:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific configuration
   ```

4. Deploy the infrastructure:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Directory Structure

```
├── deployments/           # Infrastructure deployment templates
│   ├── aws/              # AWS-specific deployments
│   ├── azure/            # Azure-specific deployments
│   └── gcp/              # Google Cloud Platform deployments
├── modules/              # Reusable Terraform modules
├── scripts/              # Deployment and utility scripts
├── docs/                 # Documentation and guides
└── examples/             # Example configurations
```

## Documentation

- [AWS Deployment Guide](docs/aws-deployment.md)
- [Azure Deployment Guide](docs/azure-deployment.md)
- [GCP Deployment Guide](docs/gcp-deployment.md)
- [Security Configuration](docs/security-config.md)
- [Troubleshooting](docs/troubleshooting.md)

## Contributing

Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions, please contact the OPSWAT team or create an issue in this repository.
