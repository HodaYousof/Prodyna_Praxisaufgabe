data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

module "network" {
  source = "./modules/network"

  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = var.location
  environment              = var.environment
  vnet_address_space       = var.vnet_address_space
  subnet_aks_address       = var.subnet_aks_address
  subnet_endpoints_address = var.subnet_endpoints_address
}

module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

module "storage" {
  source = "./modules/storage"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
}

module "aks" {
  source = "./modules/aks"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  subnet_id           = module.network.aks_subnet_id
}

module "private_endpoints" {
  source = "./modules/private-endpoints"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  endpoints_subnet_id = module.network.endpoints_subnet_id
  vnet_id             = module.network.vnet_id
  key_vault_id        = module.keyvault.id
  storage_account_id  = module.storage.id
}

resource "azurerm_role_assignment" "aks_kv_secrets_user" {
  principal_id         = module.aks.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = module.keyvault.id
}

resource "azurerm_role_assignment" "admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = module.keyvault.id
}
