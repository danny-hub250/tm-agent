variable "name" {}
variable "resource_group_name" {}
variable "location" {}

variable "project_name" {
  description = "Foundry Project(Microsoft.CognitiveServices/accounts/projects) 이름. null이면 생성하지 않음"
  type        = string
  default     = null
}

variable "firewall_allowed_ip_rules" {
  description = "Cognitive Account 방화벽(network_acls)에서 허용할 공인 IP CIDR 목록. 비어있으면 network_acls를 설정하지 않음(기본값 = 전체 네트워크 허용)"
  type        = list(string)
  default     = []
}


variable "tags" {
  type    = map(string)
  default = {}
}

variable "model_deployments" {
  description = "Foundry(Cognitive Account)에 배포할 OpenAI 모델 목록. 키가 배포(deployment) 이름이 됩니다."
  type = map(object({
    model_name             = string
    model_version          = string
    sku_name               = optional(string, "GlobalStandard")
    capacity               = optional(number, 10)
    version_upgrade_option = optional(string, "OnceCurrentVersionExpired")
  }))

  default = {
    "gpt-5-mini" = {
      model_name    = "gpt-5-mini"
      model_version = "2025-08-07"
    }
  }
}
