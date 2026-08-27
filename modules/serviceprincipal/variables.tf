variable "display_name" {}

variable "secret_validity_days" {
  description = "클라이언트 시크릿 유효기간(일). 이 기간이 지나면 다음 apply 시 time_rotating이 갱신되며 시크릿도 재발급됨"
  type        = number
  default     = 365
}
