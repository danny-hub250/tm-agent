# CI/CD 파이프라인이 aide-dev/aide-prd의 Container Registry에 push/pull(및 관리 작업)을
# 할 수 있도록 만드는 공용 Service Principal + 커스텀 Role(full-admin-acr) + Role Assignment.
#
# - SP는 테넌트(skinc-aide / taidesk.onmicrosoft.com) 하위에 1개만 생성해 dev/prd 공용으로 사용.
# - aide-dev/aide-prd는 서로 다른 구독(aide-dev / aide-prd)이라, role assignment 대상마다
#   azurerm provider를 구독별로 분리해서 사용(providers.tf의 azurerm.dev / azurerm.prd).
# - 역할은 참고 프로젝트(skbax)의 "full-admin-acr" 커스텀 역할(ACR 관리 전반)을 그대로 재현.
#
# 주의: aide-dev/aide-prd 환경(리소스그룹)이 먼저 배포되어 있어야 아래 data 조회가 성공함.

module "cicd_sp" {
  source = "../../modules/serviceprincipal"

  display_name = "aidecr-sp"
}

data "azurerm_resource_group" "dev" {
  provider = azurerm.dev
  name     = "aide-ai-dev-rg"
}

data "azurerm_resource_group" "prd" {
  provider = azurerm.prd
  name     = "aide-ai-prd-rg"
}

resource "azurerm_role_definition" "full_admin_acr" {
  provider = azurerm.dev

  name        = "full-admin-acr"
  scope       = "/subscriptions/3c71accf-dcb0-4a1d-8c8b-8e363c06a8bb" # aide-dev 구독에 등록
  description = "Full administrative access to Azure Container Registry"

  assignable_scopes = [
    "/subscriptions/3c71accf-dcb0-4a1d-8c8b-8e363c06a8bb", # aide-dev
    "/subscriptions/dc07dd36-71ed-4355-8c70-0a753a948c63", # aide-prd
  ]

  permissions {
    actions = [
      "Microsoft.ContainerRegistry/register/action",
      "Microsoft.ContainerRegistry/unregister/action",
      "Microsoft.ContainerRegistry/checkNameAvailability/read",
      "Microsoft.ContainerRegistry/locations/deleteVirtualNetworkOrSubnets/action",
      "Microsoft.ContainerRegistry/locations/operationResults/read",
      "Microsoft.ContainerRegistry/operations/read",
      "Microsoft.ContainerRegistry/registries/read",
      "Microsoft.ContainerRegistry/registries/write",
      "Microsoft.ContainerRegistry/registries/delete",
      "Microsoft.ContainerRegistry/registries/listCredentials/action",
      "Microsoft.ContainerRegistry/registries/regenerateCredential/action",
      "Microsoft.ContainerRegistry/registries/generateCredentials/action",
      "Microsoft.ContainerRegistry/registries/importImage/action",
      "Microsoft.ContainerRegistry/registries/listBuildSourceUploadUrl/action",
      "Microsoft.ContainerRegistry/registries/scheduleRun/action",
      "Microsoft.ContainerRegistry/registries/privateEndpointConnectionsApproval/action",
      "Microsoft.ContainerRegistry/registries/packages/archives/read",
      "Microsoft.ContainerRegistry/registries/packages/archives/write",
      "Microsoft.ContainerRegistry/registries/packages/archives/delete",
      "Microsoft.ContainerRegistry/registries/packages/archives/versions/read",
      "Microsoft.ContainerRegistry/registries/packages/archives/versions/write",
      "Microsoft.ContainerRegistry/registries/packages/archives/versions/delete",
      "Microsoft.ContainerRegistry/registries/packages/archives/versions/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/privateEndpointConnections/read",
      "Microsoft.ContainerRegistry/registries/privateEndpointConnections/write",
      "Microsoft.ContainerRegistry/registries/privateEndpointConnections/delete",
      "Microsoft.ContainerRegistry/registries/privateEndpointConnections/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/privateEndpointConnectionProxies/validate/action",
      "Microsoft.ContainerRegistry/registries/privateEndpointConnectionProxies/read",
      "Microsoft.ContainerRegistry/registries/privateEndpointConnectionProxies/write",
      "Microsoft.ContainerRegistry/registries/privateEndpointConnectionProxies/delete",
      "Microsoft.ContainerRegistry/registries/privateEndpointConnectionProxies/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/agentpools/read",
      "Microsoft.ContainerRegistry/registries/agentpools/write",
      "Microsoft.ContainerRegistry/registries/agentpools/delete",
      "Microsoft.ContainerRegistry/registries/agentpools/listQueueStatus/action",
      "Microsoft.ContainerRegistry/registries/agentpools/operationResults/status/read",
      "Microsoft.ContainerRegistry/registries/agentpools/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/artifacts/delete",
      "Microsoft.ContainerRegistry/registries/deleted/read",
      "Microsoft.ContainerRegistry/registries/deleted/restore/action",
      "Microsoft.ContainerRegistry/registries/listPolicies/read",
      "Microsoft.ContainerRegistry/registries/listUsages/read",
      "Microsoft.ContainerRegistry/registries/metadata/read",
      "Microsoft.ContainerRegistry/registries/metadata/write",
      "Microsoft.ContainerRegistry/registries/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/providers/Microsoft.Insights/diagnosticSettings/read",
      "Microsoft.ContainerRegistry/registries/providers/Microsoft.Insights/diagnosticSettings/write",
      "Microsoft.ContainerRegistry/registries/pull/read",
      "Microsoft.ContainerRegistry/registries/push/write",
      "Microsoft.ContainerRegistry/registries/quarantine/read",
      "Microsoft.ContainerRegistry/registries/quarantine/write",
      "Microsoft.ContainerRegistry/registries/runs/read",
      "Microsoft.ContainerRegistry/registries/runs/write",
      "Microsoft.ContainerRegistry/registries/runs/listLogSasUrl/action",
      "Microsoft.ContainerRegistry/registries/runs/cancel/action",
      "Microsoft.ContainerRegistry/registries/sign/write",
      "Microsoft.ContainerRegistry/registries/taskruns/read",
      "Microsoft.ContainerRegistry/registries/taskruns/write",
      "Microsoft.ContainerRegistry/registries/taskruns/delete",
      "Microsoft.ContainerRegistry/registries/taskruns/listDetails/action",
      "Microsoft.ContainerRegistry/registries/taskruns/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/tasks/read",
      "Microsoft.ContainerRegistry/registries/tasks/write",
      "Microsoft.ContainerRegistry/registries/tasks/delete",
      "Microsoft.ContainerRegistry/registries/tasks/listDetails/action",
      "Microsoft.ContainerRegistry/registries/updatePolicies/write",
      "Microsoft.ContainerRegistry/registries/cacheRules/read",
      "Microsoft.ContainerRegistry/registries/cacheRules/write",
      "Microsoft.ContainerRegistry/registries/cacheRules/delete",
      "Microsoft.ContainerRegistry/registries/cacheRules/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/connectedRegistries/read",
      "Microsoft.ContainerRegistry/registries/connectedRegistries/write",
      "Microsoft.ContainerRegistry/registries/connectedRegistries/delete",
      "Microsoft.ContainerRegistry/registries/connectedRegistries/deactivate/action",
      "Microsoft.ContainerRegistry/registries/credentialSets/read",
      "Microsoft.ContainerRegistry/registries/credentialSets/write",
      "Microsoft.ContainerRegistry/registries/credentialSets/delete",
      "Microsoft.ContainerRegistry/registries/credentialSets/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/eventGridFilters/read",
      "Microsoft.ContainerRegistry/registries/eventGridFilters/write",
      "Microsoft.ContainerRegistry/registries/eventGridFilters/delete",
      "Microsoft.ContainerRegistry/registries/exportPipelines/read",
      "Microsoft.ContainerRegistry/registries/exportPipelines/write",
      "Microsoft.ContainerRegistry/registries/exportPipelines/delete",
      "Microsoft.ContainerRegistry/registries/importPipelines/read",
      "Microsoft.ContainerRegistry/registries/importPipelines/write",
      "Microsoft.ContainerRegistry/registries/importPipelines/delete",
      "Microsoft.ContainerRegistry/registries/pipelineRuns/read",
      "Microsoft.ContainerRegistry/registries/pipelineRuns/write",
      "Microsoft.ContainerRegistry/registries/pipelineRuns/delete",
      "Microsoft.ContainerRegistry/registries/pipelineRuns/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/replications/read",
      "Microsoft.ContainerRegistry/registries/replications/write",
      "Microsoft.ContainerRegistry/registries/replications/delete",
      "Microsoft.ContainerRegistry/registries/replications/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/scopeMaps/read",
      "Microsoft.ContainerRegistry/registries/scopeMaps/write",
      "Microsoft.ContainerRegistry/registries/scopeMaps/delete",
      "Microsoft.ContainerRegistry/registries/scopeMaps/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/tokens/read",
      "Microsoft.ContainerRegistry/registries/tokens/write",
      "Microsoft.ContainerRegistry/registries/tokens/delete",
      "Microsoft.ContainerRegistry/registries/tokens/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/webhooks/read",
      "Microsoft.ContainerRegistry/registries/webhooks/write",
      "Microsoft.ContainerRegistry/registries/webhooks/delete",
      "Microsoft.ContainerRegistry/registries/webhooks/getCallbackConfig/action",
      "Microsoft.ContainerRegistry/registries/webhooks/ping/action",
      "Microsoft.ContainerRegistry/registries/webhooks/listEvents/action",
      "Microsoft.ContainerRegistry/registries/webhooks/operationStatuses/read",
      "Microsoft.ContainerRegistry/registries/providers/Microsoft.Insights/logDefinitions/read",
      "Microsoft.ContainerRegistry/registries/providers/Microsoft.Insights/metricDefinitions/read",
    ]

    not_actions      = []
    data_actions     = []
    not_data_actions = []
  }
}

resource "azurerm_role_assignment" "acr_admin_dev" {
  provider = azurerm.dev

  scope              = data.azurerm_resource_group.dev.id
  role_definition_id = azurerm_role_definition.full_admin_acr.role_definition_resource_id
  principal_id       = module.cicd_sp.object_id
}

resource "azurerm_role_assignment" "acr_admin_prd" {
  provider = azurerm.prd

  scope              = data.azurerm_resource_group.prd.id
  role_definition_id = azurerm_role_definition.full_admin_acr.role_definition_resource_id
  principal_id       = module.cicd_sp.object_id
}
