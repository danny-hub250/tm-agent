variable "name" {}
variable "location" {}
variable "resource_group_name" {}

variable "subnet_id" {}

variable "resource_id" {}

variable "subresource_names" {
  type = list(string)
}

variable "private_dns_zone_ids" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
