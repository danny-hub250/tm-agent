output "id" {
  value = azurerm_container_registry.acr.id
}

output "name" {
  value = azurerm_container_registry.acr.name
}

output "login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "data_endpoint_host_names" {
  description = "지역별 전용 데이터 엔드포인트 목록 (예: <registry>.<region>.data.azurecr.io)"
  value       = azurerm_container_registry.acr.data_endpoint_host_names
}
