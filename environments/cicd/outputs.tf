output "client_id" {
  value = module.cicd_sp.application_id
}

output "tenant_id" {
  value = module.cicd_sp.tenant_id
}

output "client_secret" {
  value     = module.cicd_sp.client_secret
  sensitive = true
}
