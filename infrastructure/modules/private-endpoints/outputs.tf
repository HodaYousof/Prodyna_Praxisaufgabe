output "key_vault_private_endpoint_id" {
  value = azurerm_private_endpoint.kv.id
}

output "storage_private_endpoint_id" {
  value = azurerm_private_endpoint.storage.id
}
