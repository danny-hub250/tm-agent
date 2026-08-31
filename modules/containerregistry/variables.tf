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
