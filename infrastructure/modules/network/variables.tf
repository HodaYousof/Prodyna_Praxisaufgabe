variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
}

variable "subnet_aks_address" {
  type = list(string)
}

variable "subnet_endpoints_address" {
  type = list(string)
}
