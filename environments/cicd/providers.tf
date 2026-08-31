# SP(앱 등록)는 테넌트 하위에 하나만 생성 - 기본(별칭 없는) azuread provider 사용.
provider "azuread" {
  tenant_id = "06c7ea6f-b5db-4ca2-a0fe-e1d59620e937" # skinc-aide (taidesk.onmicrosoft.com)
}

# dev/prd가 서로 다른 구독이라, role assignment를 위해 구독별로 azurerm provider를 분리.
provider "azurerm" {
  alias = "dev"
  features {}

  subscription_id = "3c71accf-dcb0-4a1d-8c8b-8e363c06a8bb" # aide-dev
  tenant_id       = "06c7ea6f-b5db-4ca2-a0fe-e1d59620e937"
}

provider "azurerm" {
  alias = "prd"
  features {}

  subscription_id = "dc07dd36-71ed-4355-8c70-0a753a948c63" # aide-prd
  tenant_id       = "06c7ea6f-b5db-4ca2-a0fe-e1d59620e937"
}
