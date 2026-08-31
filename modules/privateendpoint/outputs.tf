output "id" {
  value = azurerm_private_endpoint.privateendpoint.id
}

output "dns_configs" {
  description = "방화벽 신청 등에 사용할 FQDN-IP 매핑 목록 ({fqdn, ip_addresses})"
  value       = azurerm_private_endpoint.privateendpoint.custom_dns_configs
}
