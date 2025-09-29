variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "vnet_cidr" {
  description = "CIDR block for VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed for administrative access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "public_key" {
  description = "Public key for VM access"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size for MetaDefender Core"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_instances" {
  description = "Number of VM instances in scale set"
  type        = number
  default     = 1
}

variable "metadefender_license_key" {
  description = "MetaDefender Core license key"
  type        = string
  default     = ""
  sensitive   = true
}