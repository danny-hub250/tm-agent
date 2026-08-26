resource "azurerm_subnet" "subnet" {

  name                 = var.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name

  address_prefixes = var.address_prefixes

  service_endpoints = var.service_endpoints

  dynamic "delegation" {
    for_each = var.delegation_name == null ? [] : [1]

    content {
      name = var.delegation_name

      service_delegation {
        name    = var.service_delegation_name
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }

}
