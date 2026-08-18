terraform {
  backend "azurerm" {
    resource_group_name  = "RG-Hoda-Yousof"
    storage_account_name = "stprodynaterraform"
    container_name       = "tfstate"
    key                  = "prodyna-dev.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}
resource "azurerm_virtual_network" "main" {
  name                = "vnet-prodyna-${var.environment}"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
}
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks-prodyna-${var.environment}"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_aks_address

}
resource "azurerm_subnet" "endpoints" {
  name                 = "snet-endpoints-prodyna-${var.environment}"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_endpoints_address

}
resource "azurerm_network_security_group" "main" {
  name                = "nsg-prodyna-${var.environment}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

}
resource "azurerm_subnet_network_security_group_association" "endpoints" {
  subnet_id                 = azurerm_subnet.endpoints.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_key_vault" "main" {
  name                       = "kv-prodyna-${var.environment}"
  resource_group_name        = data.azurerm_resource_group.main.name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  rbac_authorization_enabled = true

}
resource "azurerm_private_endpoint" "kv" {
  name                = "pe-kv-prodyna-${var.environment}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = "psc-kv-prodyna-${var.environment}"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
  private_dns_zone_group {
    name                 = "pdzg-kv"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv.id]

  }
}
resource "azurerm_storage_account" "main" {
  name                     = "stprodyna${var.environment}"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_private_endpoint" "storage" {
  name                = "pe-prodyna-${var.environment}"
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.endpoints.id
  location            = var.location
  private_service_connection {
    name                           = "pstkv-prodyna${var.environment}"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  private_dns_zone_group {
    name                 = "pdzg-st"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-prodyna-${var.environment}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  dns_prefix          = "aks-prodyna-${var.environment}"

  default_node_pool {
    name           = "system"
    vm_size        = "Standard_B2s_v2"
    node_count     = 1
    vnet_subnet_id = azurerm_subnet.aks.id
  }
  identity {
    type = "SystemAssigned"
  }
  network_profile {
    network_plugin = "azure"
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }

}
resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.main.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = "vnetlink-kv-prodyna-${var.environment}"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "vnetlink-st-prodyna-${var.environment}"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
resource "azurerm_role_assignment" "main" {
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.main.id

}
resource "azurerm_role_assignment" "admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.main.id
}