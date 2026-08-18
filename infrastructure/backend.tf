terraform {
  backend "azurerm" {
    resource_group_name  = "RG-Hoda-Yousof"
    storage_account_name = "stprodynaterraform"
    container_name       = "tfstate"
    key                  = "prodyna-dev.tfstate"
  }
}
