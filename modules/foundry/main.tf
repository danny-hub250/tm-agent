resource "azurerm_cognitive_account" "foundry" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "AIServices"

  sku_name              = "S0"
  custom_subdomain_name = var.name
  tags                  = var.tags
}

resource "azurerm_cognitive_account_project" "this" {
  count = var.project_name != null ? 1 : 0

  name                 = var.project_name
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  location             = var.location
  tags                 = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_deployment" "this" {
  for_each = var.model_deployments

  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  version_upgrade_option = each.value.version_upgrade_option

  sku {
    name     = each.value.sku_name
    capacity = each.value.capacity
  }
}
