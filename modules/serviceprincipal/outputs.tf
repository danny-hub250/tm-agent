output "application_id" {
  description = "client_id (앱 ID) - CI/CD에서 로그인 시 사용"
  value       = azuread_application.this.client_id
}

output "object_id" {
  description = "Service Principal object_id - azurerm_role_assignment의 principal_id로 사용"
  value       = azuread_service_principal.this.object_id
}

output "tenant_id" {
  value = azuread_service_principal.this.application_tenant_id
}

output "client_secret" {
  value     = azuread_application_password.this.value
  sensitive = true
}
