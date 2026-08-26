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
