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

output "primary_access_key" {
  value     = azurerm_cognitive_account.foundry.primary_access_key
  sensitive = true
}
