module "ai-rg" {
  source   = "../../modules/resourcegroup"
  name     = "taide-ai-prd-rg"
  location = var.location
  tags     = var.tags
}

# --- Private Endpoint용 네트워크 ---

module "vnet" {
  source              = "../../modules/virtualnetwork"
  name                = "taide-p-vnet"
  location            = var.location
  resource_group_name = module.ai-rg.name
  address_space       = ["10.161.0.0/24"]
  tags                = var.tags
}

module "subnet_private_endpoint" {
  source              = "../../modules/subnet"
  name                = "taide-pe-p-snet"
  resource_group_name = module.ai-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.161.0.0/25"]
}

module "openai_dns" {
  source              = "../../modules/privatednszone"
  name                = "privatelink.openai.azure.com"
  resource_group_name = module.ai-rg.name
  tags                = var.tags
}

module "openai_dns_link" {
  source              = "../../modules/privatednszonelink"
  name                = "taide-p-openai-dns-link"
  resource_group_name = module.ai-rg.name
  dns_zone_name       = module.openai_dns.name
  vnet_id             = module.vnet.id
}

module "cog_dns" {
  source              = "../../modules/privatednszone"
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = module.ai-rg.name
  tags                = var.tags
}

module "cog_dns_link" {
  source              = "../../modules/privatednszonelink"
  name                = "taide-p-cog-dns-link"
  resource_group_name = module.ai-rg.name
  dns_zone_name       = module.cog_dns.name
  vnet_id             = module.vnet.id
}

module "serviceai_dns" {
  source              = "../../modules/privatednszone"
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = module.ai-rg.name
  tags                = var.tags
}

module "serviceai_dns_link" {
  source              = "../../modules/privatednszonelink"
  name                = "taide-p-serviceai-dns-link"
  resource_group_name = module.ai-rg.name
  dns_zone_name       = module.serviceai_dns.name
  vnet_id             = module.vnet.id
}

# AI Search는 AKS 내 OSS(예: OpenSearch 등)로 대체 설치 예정이라 비활성화.
# 향후 Azure AI Search를 다시 사용할 경우를 대비해 코드는 유지.
# module "search_dns" {
#   source              = "../../modules/privatednszone"
#   name                = "privatelink.search.windows.net"
#   resource_group_name = module.ai-rg.name
#   tags                = var.tags
# }
#
# module "search_dns_link" {
#   source              = "../../modules/privatednszonelink"
#   name                = "taide-p-search-dns-link"
#   resource_group_name = module.ai-rg.name
#   dns_zone_name       = module.search_dns.name
#   vnet_id             = module.vnet.id
# }

module "acr_dns" {
  source              = "../../modules/privatednszone"
  name                = "privatelink.azurecr.io"
  resource_group_name = module.ai-rg.name
  tags                = var.tags
}

module "acr_dns_link" {
  source              = "../../modules/privatednszonelink"
  name                = "taide-p-acr-dns-link"
  resource_group_name = module.ai-rg.name
  dns_zone_name       = module.acr_dns.name
  vnet_id             = module.vnet.id
}

# --- AI Foundry ---

module "foundry" {
  source = "../../modules/foundry"

  name                = "taide-p-msf"
  location            = "EastUS2"
  resource_group_name = module.ai-rg.name
  tags                = var.tags

  # NOTE: 2026-08-27 기준 mySUNI AI Portal - LJK 구독의 EastUS2 OpenAI GlobalStandard
  # quota가 taide-dev 배포로 모델당 1000/1000(잔여 0)까지 이미 소진된 상태라, 원래 목표
  # capacity를 훨씬 못 미치는 100으로 임시로 낮춰 배포함(그래도 quota 초과로 실패할 수 있음).
  # Azure에 quota 증설 요청 후 승인되면 아래 원래 값으로 복원할 것.
  # (원래 목표: gpt-5.5=5997, gpt-5.6-luna=2997, gpt-5.6-sol=7993, gpt-5.6-terra=6001,
  #  text-embedding-3-large=1964)
  model_deployments = {
    "gpt-5.5" = {
      model_name    = "gpt-5.5"
      model_version = "2026-04-24"
      capacity      = 100
    }
    "gpt-5.6-luna" = {
      model_name    = "gpt-5.6-luna"
      model_version = "2026-07-09"
      capacity      = 100
    }
    "gpt-5.6-sol" = {
      model_name    = "gpt-5.6-sol"
      model_version = "2026-07-09"
      capacity      = 100
    }
    "gpt-5.6-terra" = {
      model_name    = "gpt-5.6-terra"
      model_version = "2026-07-09"
      capacity      = 100
    }
    "text-embedding-3-large" = {
      model_name    = "text-embedding-3-large"
      model_version = "1"
      capacity      = 100
    }
  }
}

module "foundry_pe" {
  source = "../../modules/privateendpoint"

  name                = "taide-p-msf-pe"
  location            = var.location
  resource_group_name = module.ai-rg.name
  subnet_id           = module.subnet_private_endpoint.id
  resource_id         = module.foundry.id
  subresource_names   = ["account"]

  private_dns_zone_ids = [
    module.openai_dns.id,
    module.cog_dns.id,
    module.serviceai_dns.id
  ]
  tags = var.tags
}

# --- AI Search ---
# AI Search는 AKS 내 OSS(예: OpenSearch 등)로 대체 설치 예정이라 비활성화.
# 향후 Azure AI Search를 다시 사용할 경우를 대비해 코드는 유지.

# module "ai_search" {
#   source = "../../modules/aisearch"
#
#   name                = "taide-p-srch01"
#   location            = var.location
#   resource_group_name = module.ai-rg.name
#   sku                 = "basic"
#   tags                = var.tags
# }
#
# module "search_pe" {
#   source = "../../modules/privateendpoint"
#
#   name                = "taide-p-srch01-pe"
#   location            = var.location
#   resource_group_name = module.ai-rg.name
#   subnet_id           = module.subnet_private_endpoint.id
#   resource_id         = module.ai_search.id
#   subresource_names   = ["searchService"]
#
#   private_dns_zone_ids = [
#     module.search_dns.id
#   ]
#   tags = var.tags
# }

# --- Container Registry ---

module "acr" {
  source = "../../modules/containerregistry"

  name                = "taideprdcr"
  location            = var.location
  resource_group_name = module.ai-rg.name
  sku                 = "Premium"
  tags                = var.tags
}

module "acr_pe" {
  source = "../../modules/privateendpoint"

  name                = "taideprdcr-pe"
  location            = var.location
  resource_group_name = module.ai-rg.name
  subnet_id           = module.subnet_private_endpoint.id
  resource_id         = module.acr.id
  subresource_names   = ["registry"]

  private_dns_zone_ids = [
    module.acr_dns.id
  ]
  tags = var.tags
}
