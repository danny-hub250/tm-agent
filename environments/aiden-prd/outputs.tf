# 개발자 전달용 엔드포인트 목록 (04. 리소스 구성 내역 시트의 Azure 엔드포인트 표 대응)

output "aoai_openai_endpoint" {
  value = "https://${module.foundry.name}.openai.azure.com/"
}

output "aoai_cognitiveservices_endpoint" {
  value = "https://${module.foundry.name}.cognitiveservices.azure.com"
}

output "aoai_services_ai_endpoint" {
  value = "https://${module.foundry.name}.services.ai.azure.com"
}

output "acr_login_server_endpoint" {
  value = "https://${module.acr.login_server}"
}

output "acr_data_endpoints" {
  value = [for h in module.acr.data_endpoint_host_names : "https://${h}"]
}

output "firewall_endpoints" {
  description = "방화벽 신청용 FQDN-IP 매핑 (Foundry PE + ACR PE, {fqdn, ip_addresses})"
  value = concat(
    module.foundry_pe.dns_configs,
    module.acr_pe.dns_configs,
  )
}
