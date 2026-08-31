output "endpoint" {
  value = azurerm_cognitive_account.foundry.endpoint
}

output "id" {
  value = azurerm_cognitive_account.foundry.id
}

output "name" {
  value = azurerm_cognitive_account.foundry.name

}

output "deployment_names" {
  value = [for d in azurerm_cognitive_deployment.this : d.name]
}

output "project_id" {
  value = try(azurerm_cognitive_account_project.this[0].id, null)
}

output "project_endpoints" {
  description = "Foundry Project 엔드포인트 맵 (예: AI Foundry API 엔드포인트 등)"
  value       = try(azurerm_cognitive_account_project.this[0].endpoints, null)
}

output "primary_access_key" {
  value     = azurerm_cognitive_account.foundry.primary_access_key
  sensitive = true
}
