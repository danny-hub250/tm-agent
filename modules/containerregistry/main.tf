resource "azurerm_container_registry" "acr" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku                   = var.sku
  admin_enabled         = var.admin_enabled
  data_endpoint_enabled = var.data_endpoint_enabled

  # 방화벽: 지정된 IP만 허용하고 나머지는 차단(Private Endpoint 경유 트래픽 및 Azure
  # 신뢰할 수 있는 서비스는 별도로 허용됨). firewall_allowed_ip_rules가 비어있으면
  # null을 넘겨 기본 동작(전체 허용)을 유지함.
  network_rule_bypass_option = length(var.firewall_allowed_ip_rules) > 0 ? "AzureServices" : null
  network_rule_set = length(var.firewall_allowed_ip_rules) > 0 ? [{
    default_action = "Deny"
    ip_rule = [for ip in var.firewall_allowed_ip_rules : {
      action   = "Allow"
      ip_range = ip
    }]
  }] : null

  tags = var.tags
}
