variable "resource_group_name" {
  type        = string
  description = "Existing Azure Resource Group for state storage"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "westeurope"
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique storage account name for Terraform state"
  default     = "stprodynaterraform"
}

variable "container_name" {
  type        = string
  description = "Blob container for state files"
  default     = "tfstate"
}
