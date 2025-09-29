#!/bin/bash
# OPSWAT Demo Deployment Script

set -e

# Configuration
DEPLOYMENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_DEPLOYMENT_DIR="${DEPLOYMENT_DIR}/../deployments/aws/basic-demo"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    log_info "Checking requirements..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform >= 1.0"
        exit 1
    fi
    
    # Check Terraform version
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log_info "Terraform version: $TERRAFORM_VERSION"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install AWS CLI"
        exit 1
    fi
    
    # Check AWS configuration
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured. Please run 'aws configure'"
        exit 1
    fi
    
    log_info "All requirements satisfied!"
}

deploy_aws() {
    log_info "Deploying OPSWAT demo on AWS..."
    
    cd "$AWS_DEPLOYMENT_DIR"
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        log_error "terraform.tfvars not found. Please copy terraform.tfvars.example to terraform.tfvars and configure it."
        exit 1
    fi
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Validate configuration
    log_info "Validating Terraform configuration..."
    terraform validate
    
    # Plan deployment
    log_info "Planning deployment..."
    terraform plan -out=tfplan
    
    # Apply deployment
    log_info "Applying deployment..."
    terraform apply tfplan
    
    # Show outputs
    log_info "Deployment completed! Here are the important outputs:"
    terraform output
    
    log_info "You can access MetaDefender Core at: $(terraform output -raw load_balancer_url)"
}

destroy_aws() {
    log_info "Destroying OPSWAT demo on AWS..."
    
    cd "$AWS_DEPLOYMENT_DIR"
    
    # Destroy infrastructure
    log_warn "This will destroy all resources. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        terraform destroy
        log_info "Infrastructure destroyed!"
    else
        log_info "Destruction cancelled."
    fi
}

show_help() {
    echo "OPSWAT Demo Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy-aws    Deploy OPSWAT demo on AWS"
    echo "  destroy-aws   Destroy OPSWAT demo on AWS"
    echo "  check         Check requirements"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 check"
    echo "  $0 deploy-aws"
    echo "  $0 destroy-aws"
}

# Main logic
case "${1:-help}" in
    "check")
        check_requirements
        ;;
    "deploy-aws")
        check_requirements
        deploy_aws
        ;;
    "destroy-aws")
        destroy_aws
        ;;
    "help")
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac