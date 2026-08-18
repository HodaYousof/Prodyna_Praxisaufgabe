resource "azurerm_virtual_network" "main" {
  name                = "vnet-prodyna-${var.environment}"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks-prodyna-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_aks_address
}

resource "azurerm_subnet" "endpoints" {
  name                 = "snet-endpoints-prodyna-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_endpoints_address
}

resource "azurerm_network_security_group" "main" {
  name                = "nsg-prodyna-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_subnet_network_security_group_association" "endpoints" {
  subnet_id                 = azurerm_subnet.endpoints.id
  network_security_group_id = azurerm_network_security_group.main.id
}
