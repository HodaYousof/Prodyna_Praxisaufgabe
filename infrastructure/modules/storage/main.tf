resource "azurerm_storage_account" "main" {
  name                     = "stprodyna${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
