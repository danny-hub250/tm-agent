output "id" {
  value = azurerm_private_endpoint.privateendpoint.id
}

output "dns_configs" {
  description = "방화벽 신청 등에 사용할 FQDN-IP 매핑 목록 ({fqdn, ip_addresses})"
  # private_dns_zone_group을 사용하는 구성에서는 custom_dns_configs가 항상 빈 목록으로
  # 남고, 실제 레코드는 private_dns_zone_configs[].record_sets[]에 생성되므로 이를 사용.
  value = flatten([
    for zone_config in azurerm_private_endpoint.privateendpoint.private_dns_zone_configs : [
      for record_set in zone_config.record_sets : {
        fqdn         = record_set.fqdn
        ip_addresses = record_set.ip_addresses
      }
    ]
  ])
}
