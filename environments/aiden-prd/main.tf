module "ai-rg" {
  source   = "../../modules/resourcegroup"
  name     = "aiden-ai-prd-rg"
  location = var.location
  tags     = var.tags
}

# --- Private Endpoint용 네트워크 ---

module "vnet" {
  source              = "../../modules/virtualnetwork"
  name                = "aiden-p-vnet"
  location            = var.location
  resource_group_name = module.ai-rg.name
  address_space       = ["10.70.254.32/27"]
  tags                = var.tags
}

module "subnet_private_endpoint" {
  source              = "../../modules/subnet"
  name                = "aiden-pe-p-snet"
  resource_group_name = module.ai-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.70.254.32/27"]
}

module "openai_dns" {
  source              = "../../modules/privatednszone"
  name                = "privatelink.openai.azure.com"
  resource_group_name = module.ai-rg.name
  tags                = var.tags
}

module "openai_dns_link" {
  source              = "../../modules/privatednszonelink"
  name                = "aiden-p-openai-dns-link"
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
  name                = "aiden-p-cog-dns-link"
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
  name                = "aiden-p-serviceai-dns-link"
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
#   name                = "aiden-p-search-dns-link"
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
  name                = "aiden-p-acr-dns-link"
  resource_group_name = module.ai-rg.name
  dns_zone_name       = module.acr_dns.name
  vnet_id             = module.vnet.id
}

# --- AI Foundry ---

module "foundry" {
  source = "../../modules/foundry"

  name                = "aiden-p-msf"
  location            = "EastUS2"
  resource_group_name = module.ai-rg.name
  tags                = var.tags
  project_name        = "aiden-p-msf-aidenagent"

  model_deployments = {
    "gpt-5.5" = {
      model_name    = "gpt-5.5"
      model_version = "2026-04-24"
      capacity      = 5997
    }
    "gpt-5.6-luna" = {
      model_name    = "gpt-5.6-luna"
      model_version = "2026-07-09"
      capacity      = 2997
    }
    "gpt-5.6-sol" = {
      model_name    = "gpt-5.6-sol"
      model_version = "2026-07-09"
      capacity      = 7993
    }
    "gpt-5.6-terra" = {
      model_name    = "gpt-5.6-terra"
      model_version = "2026-07-09"
      capacity      = 6001
    }
    "text-embedding-3-large" = {
      model_name    = "text-embedding-3-large"
      model_version = "1"
      capacity      = 1964
    }
  }
}

module "foundry_pe" {
  source = "../../modules/privateendpoint"

  name                = "aiden-p-msf-pe"
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
#   name                = "aiden-p-srch01"
#   location            = var.location
#   resource_group_name = module.ai-rg.name
#   sku                 = "basic"
#   tags                = var.tags
# }
#
# module "search_pe" {
#   source = "../../modules/privateendpoint"
#
#   name                = "aiden-p-srch01-pe"
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

  name                = "aidenprdcr"
  location            = var.location
  resource_group_name = module.ai-rg.name
  sku                 = "Premium"
  tags                = var.tags
}

module "acr_pe" {
  source = "../../modules/privateendpoint"

  name                = "aidenprdcr-pe"
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
