resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-prodyna-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = "aks-prodyna-${var.environment}"

  default_node_pool {
    name           = "system"
    vm_size        = var.vm_size
    node_count     = var.node_count
    vnet_subnet_id = var.subnet_id

    # Azure setzt Defaults; ohne Block driftet plan ewig
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
  }
}
