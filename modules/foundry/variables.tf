variable "name" {}
variable "resource_group_name" {}
variable "location" {}


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
