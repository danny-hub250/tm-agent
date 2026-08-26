variable "name" {}
variable "resource_group_name" {}
variable "location" {}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "sku" {
  description = "Basic, Standard, Standard2, Standard3, StorageOptimized_L1, StorageOptimized_L2, Free 중 선택"
  type        = string
  default     = "standard"
}

variable "replica_count" {
  type    = number
  default = 1
}

variable "partition_count" {
  type    = number
  default = 1
}

variable "public_network_access_enabled" {
  description = "vnet/private endpoint 연계 없이 사용하는 구성이므로 기본값 true (필요 시 false로 전환하고 private endpoint 추가)"
  type        = bool
  default     = true
}
