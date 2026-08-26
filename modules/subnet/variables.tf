variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "address_prefixes" {
  type = list(string)
}

variable "service_endpoints" {
  type    = list(string)
  default = []
}

variable "nat_gateway_id" {
  type    = string
  default = null
}

variable "delegation_name" {
  type    = string
  default = null
}

variable "service_delegation_name" {
  type    = string
  default = null
}
