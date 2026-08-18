resource "azurerm_key_vault" "main" {
  name                       = "kv-prodyna-${var.environment}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  rbac_authorization_enabled = true
}
