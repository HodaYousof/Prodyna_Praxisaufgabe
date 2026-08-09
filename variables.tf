variable "location" {
  type        = string
  description = "Azure Region"
  default     = "westeurope"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the existing Azure Resource Group"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. dev, staging, prod)"
  default     = "dev"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet address space"
  default     = ["10.0.0.0/16"]
}

variable "subnet_aks_address" {
  type        = list(string)
  description = "Address prefixes for the AKS subnet"
}

variable "subnet_endpoints_address" {
  type        = list(string)
  description = "Address prefixes for the private endpoints subnet"
}
