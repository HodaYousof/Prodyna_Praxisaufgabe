output "resource_group_name" {
  value = data.azurerm_resource_group.main.name
}

output "vnet_name" {
  value = module.network.vnet_name
}

output "vnet_id" {
  value = module.network.vnet_id
}

output "aks_cluster_name" {
  value = module.aks.name
}

output "aks_subnet_id" {
  value = module.network.aks_subnet_id
}

output "endpoints_subnet_id" {
  value = module.network.endpoints_subnet_id
}

output "key_vault_name" {
  value = module.keyvault.name
}

output "key_vault_id" {
  value = module.keyvault.id
}

output "key_vault_uri" {
  value = module.keyvault.uri
}

output "storage_account_name" {
  value = module.storage.name
}

output "storage_account_id" {
  value = module.storage.id
}
