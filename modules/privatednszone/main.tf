resource "azurerm_private_dns_zone" "privatednszone" {
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
