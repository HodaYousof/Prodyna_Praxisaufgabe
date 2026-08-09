output "resource_group_name" {
    value = data.azurerm_resource_group.main.name
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}
output "vnet_id" {
  value = azurerm_virtual_network.main.id
}
output "aks_cluster_name" {
    value = azurerm_kubernetes_cluster.main.name
}
output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}
output "endpoints_subnet_id" {
  value = azurerm_subnet.endpoints.id
}
output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "key_vault_id" {
  value = azurerm_key_vault.main.id
}
output "key_vault_uri" {
    value = azurerm_key_vault.main.vault_uri
}
output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "storage_account_id" {
  value = azurerm_storage_account.main.id
}