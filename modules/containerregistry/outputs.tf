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

output "token_name" {
  value = try(azurerm_container_registry_token.this[0].name, null)
}

output "token_password" {
  description = "리포지토리 권한 토큰의 password1 값 - 배포 후 개발자/CI·CD에 전달 필요"
  value       = try(azurerm_container_registry_token_password.this[0].password1[0].value, null)
  sensitive   = true
}
