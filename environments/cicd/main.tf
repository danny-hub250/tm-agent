# CI/CD 파이프라인이 taide-dev/taide-prd의 Container Registry에 push/pull 하기 위한
# 공용 Service Principal + Role Assignment.
#
# 주의: taide-dev/taide-prd 환경(리소스그룹)이 먼저 배포되어 있어야 아래 data 조회가 성공함.

module "cicd_sp" {
  source = "../../modules/serviceprincipal"

  display_name = "taide-cicd-acr-sp"
}

data "azurerm_resource_group" "dev" {
  name = "taide-ai-dev-rg"
}

data "azurerm_resource_group" "prd" {
  name = "taide-ai-prd-rg"
}

resource "azurerm_role_assignment" "acr_push_dev" {
  scope                = data.azurerm_resource_group.dev.id
  role_definition_name = "AcrPush"
  principal_id         = module.cicd_sp.object_id
}

resource "azurerm_role_assignment" "acr_push_prd" {
  scope                = data.azurerm_resource_group.prd.id
  role_definition_name = "AcrPush"
  principal_id         = module.cicd_sp.object_id
}
