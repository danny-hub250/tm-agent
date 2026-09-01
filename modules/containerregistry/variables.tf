variable "name" {}
variable "resource_group_name" {}
variable "location" {}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "sku" {
  description = "Private Endpoint를 사용하려면 Premium이 필요"
  type        = string
  default     = "Premium"
}

variable "admin_enabled" {
  type    = bool
  default = false
}

variable "data_endpoint_enabled" {
  description = "지역별 전용 데이터 엔드포인트(<registry>.<region>.data.azurecr.io) 활성화 여부. Premium SKU 필요"
  type        = bool
  default     = true
}

variable "firewall_allowed_ip_rules" {
  description = "ACR 방화벽(network_rule_set)에서 허용할 공인 IP CIDR 목록. 비어있으면 방화벽을 설정하지 않음(기본값 = 전체 네트워크 허용)"
  type        = list(string)
  default     = []
}
