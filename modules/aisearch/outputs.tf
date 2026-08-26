output "id" {
  value = azurerm_search_service.aisearch.id
}

output "name" {
  value = azurerm_search_service.aisearch.name
}

output "primary_key" {
  value     = azurerm_search_service.aisearch.primary_key
  sensitive = true
}

output "query_keys" {
  value     = azurerm_search_service.aisearch.query_keys
  sensitive = true
}
