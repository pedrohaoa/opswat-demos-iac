# Contributing to OPSWAT Demos IaC

Thank you for your interest in contributing to the OPSWAT Infrastructure as Code repository! This document provides guidelines for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our code of conduct:
- Be respectful and inclusive
- Focus on constructive feedback
- Help create a positive learning environment

## Getting Started

### Prerequisites

- Terraform >= 1.0
- AWS CLI, Azure CLI, or gcloud CLI (depending on target cloud)
- Git
- Basic understanding of Infrastructure as Code concepts

### Setting Up Development Environment

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/opswat-demos-iac.git
   cd opswat-demos-iac
   ```
3. Install development tools:
   ```bash
   # Install pre-commit hooks
   pip install pre-commit
   pre-commit install
   
   # Install tfsec for security scanning
   brew install tfsec  # macOS
   # or
   curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash  # Linux
   ```

## Contribution Types

### 1. New Cloud Provider Support

To add support for a new cloud provider:

1. Create a new directory: `deployments/{provider}/basic-demo`
2. Implement the core modules for the provider
3. Add provider-specific documentation
4. Update the main README.md

### 2. New Deployment Scenarios

For new deployment scenarios (e.g., enterprise-pov, multi-region):

1. Create scenario directory: `deployments/{provider}/{scenario}`
2. Document the use case and architecture
3. Provide example configuration files
4. Add tests for the scenario

### 3. Module Improvements

When improving existing modules:

1. Ensure backward compatibility
2. Update variable descriptions
3. Add or update outputs as needed
4. Update relevant documentation

### 4. Bug Fixes

For bug fixes:

1. Create an issue describing the bug
2. Reference the issue in your pull request
3. Include steps to reproduce
4. Verify the fix works across supported configurations

## Development Guidelines

### Terraform Code Standards

1. **Formatting**: Use `terraform fmt` to format all code
2. **Validation**: All code must pass `terraform validate`
3. **Security**: Run `tfsec` to check for security issues
4. **Documentation**: Include descriptions for all variables and outputs

### Variable Naming Conventions

- Use snake_case for all variable names
- Include meaningful descriptions
- Set appropriate types and validation rules
- Provide sensible defaults where applicable

```hcl
variable "instance_type" {
  description = "EC2 instance type for MetaDefender Core"
  type        = string
  default     = "t3.medium"
  
  validation {
    condition     = contains(["t3.small", "t3.medium", "t3.large"], var.instance_type)
    error_message = "Instance type must be one of: t3.small, t3.medium, t3.large."
  }
}
```

### Resource Naming Conventions

- Use consistent naming patterns: `{product}-{environment}-{resource}`
- Include environment in all resource names
- Use descriptive names that indicate purpose

```hcl
resource "aws_instance" "metadefender" {
  # ... configuration
  
  tags = {
    Name = "opswat-${var.environment}-metadefender"
    Role = "MetaDefender-Core"
  }
}
```

### Security Best Practices

1. **No Hardcoded Secrets**: Use variables marked as `sensitive`
2. **Least Privilege**: Security groups should only allow necessary access
3. **Encryption**: Enable encryption for storage and data in transit
4. **Network Isolation**: Use private subnets where appropriate

### Documentation Standards

1. **README Files**: Each deployment must have a comprehensive README
2. **Code Comments**: Explain complex logic or non-obvious configurations
3. **Architecture Diagrams**: Include diagrams for complex deployments
4. **Examples**: Provide complete, working examples

## Testing Requirements

### Automated Testing

All submissions must pass:

1. **Terraform Validation**: `terraform validate`
2. **Format Check**: `terraform fmt -check`
3. **Security Scan**: `tfsec`
4. **Policy Validation**: `conftest` (where applicable)

### Manual Testing

Before submitting:

1. Test deployment in a clean environment
2. Verify all outputs are correct
3. Test resource cleanup (`terraform destroy`)
4. Validate documentation accuracy

## Submission Process

### Pull Request Guidelines

1. **Branch Naming**: Use descriptive branch names
   - `feature/azure-support`
   - `fix/aws-security-group`
   - `docs/troubleshooting-guide`

2. **Commit Messages**: Use clear, descriptive commit messages
   ```
   feat: add Azure Virtual Machine Scale Set support
   
   - Implement VMSS for MetaDefender Core
   - Add Application Gateway for load balancing
   - Include auto-scaling configuration
   ```

3. **Pull Request Description**: Include:
   - Summary of changes
   - Testing performed
   - Documentation updates
   - Breaking changes (if any)

### Review Process

1. **Automated Checks**: All CI/CD checks must pass
2. **Code Review**: At least one maintainer review required
3. **Testing**: Reviewer may test deployment in their environment
4. **Documentation**: Verify documentation is complete and accurate

## Security Considerations

### Sensitive Information

- Never commit secrets or credentials
- Use GitHub Secrets for CI/CD workflows
- Mark sensitive variables appropriately
- Review code for accidental credential exposure

### Infrastructure Security

- Follow cloud provider security best practices
- Enable logging and monitoring
- Use network segmentation
- Implement proper access controls

## Release Process

### Versioning

We use Semantic Versioning (SemVer):
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Changelog

Maintain CHANGELOG.md with:
- New features
- Bug fixes
- Breaking changes
- Migration instructions

## Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussions
- **Documentation**: Check existing documentation first
- **OPSWAT Community**: Reach out to OPSWAT community forums

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- GitHub contributor statistics

Thank you for contributing to the OPSWAT Infrastructure as Code project!