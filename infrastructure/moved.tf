# State migration from flat root layout → modules (no destroy/recreate).

moved {
  from = azurerm_virtual_network.main
  to   = module.network.azurerm_virtual_network.main
}

moved {
  from = azurerm_subnet.aks
  to   = module.network.azurerm_subnet.aks
}

moved {
  from = azurerm_subnet.endpoints
  to   = module.network.azurerm_subnet.endpoints
}

moved {
  from = azurerm_network_security_group.main
  to   = module.network.azurerm_network_security_group.main
}

moved {
  from = azurerm_subnet_network_security_group_association.endpoints
  to   = module.network.azurerm_subnet_network_security_group_association.endpoints
}

moved {
  from = azurerm_key_vault.main
  to   = module.keyvault.azurerm_key_vault.main
}

moved {
  from = azurerm_storage_account.main
  to   = module.storage.azurerm_storage_account.main
}

moved {
  from = azurerm_kubernetes_cluster.main
  to   = module.aks.azurerm_kubernetes_cluster.main
}

moved {
  from = azurerm_private_dns_zone.kv
  to   = module.private_endpoints.azurerm_private_dns_zone.kv
}

moved {
  from = azurerm_private_dns_zone_virtual_network_link.kv
  to   = module.private_endpoints.azurerm_private_dns_zone_virtual_network_link.kv
}

moved {
  from = azurerm_private_dns_zone.storage
  to   = module.private_endpoints.azurerm_private_dns_zone.storage
}

moved {
  from = azurerm_private_dns_zone_virtual_network_link.storage
  to   = module.private_endpoints.azurerm_private_dns_zone_virtual_network_link.storage
}

moved {
  from = azurerm_private_endpoint.kv
  to   = module.private_endpoints.azurerm_private_endpoint.kv
}

moved {
  from = azurerm_private_endpoint.storage
  to   = module.private_endpoints.azurerm_private_endpoint.storage
}

moved {
  from = azurerm_role_assignment.main
  to   = azurerm_role_assignment.aks_kv_secrets_user
}
