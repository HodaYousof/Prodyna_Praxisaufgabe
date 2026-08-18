output "name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "principal_id" {
  value = azurerm_kubernetes_cluster.main.identity[0].principal_id
}
