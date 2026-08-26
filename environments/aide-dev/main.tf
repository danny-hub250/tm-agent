module "ai-rg" {
  source   = "../../modules/resourcegroup"
  name     = "aide-ai-dev-rg"
  location = var.location
  tags     = var.tags
}

# --- Private Endpoint용 네트워크 ---

module "vnet" {
  source              = "../../modules/virtualnetwork"
  name                = "aide-d-vnet"
  location            = var.location
  resource_group_name = module.ai-rg.name
  address_space       = ["10.160.0.0/24"]
  tags                = var.tags
}

module "subnet_private_endpoint" {
  source              = "../../modules/subnet"
  name                = "aide-pe-d-snet"
  resource_group_name = module.ai-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.160.0.0/25"]
}

module "openai_dns" {
  source              = "../../modules/privatednszone"
  name                = "privatelink.openai.azure.com"
  resource_group_name = module.ai-rg.name
  tags                = var.tags
}

module "openai_dns_link" {
  source              = "../../modules/privatednszonelink"
  name                = "aide-d-openai-dns-link"
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
  name                = "aide-d-cog-dns-link"
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
  name                = "aide-d-serviceai-dns-link"
  resource_group_name = module.ai-rg.name
  dns_zone_name       = module.serviceai_dns.name
  vnet_id             = module.vnet.id
}

module "search_dns" {
  source              = "../../modules/privatednszone"
  name                = "privatelink.search.windows.net"
  resource_group_name = module.ai-rg.name
  tags                = var.tags
}

module "search_dns_link" {
  source              = "../../modules/privatednszonelink"
  name                = "aide-d-search-dns-link"
  resource_group_name = module.ai-rg.name
  dns_zone_name       = module.search_dns.name
  vnet_id             = module.vnet.id
}

module "acr_dns" {
  source              = "../../modules/privatednszone"
  name                = "privatelink.azurecr.io"
  resource_group_name = module.ai-rg.name
  tags                = var.tags
}

module "acr_dns_link" {
  source              = "../../modules/privatednszonelink"
  name                = "aide-d-acr-dns-link"
  resource_group_name = module.ai-rg.name
  dns_zone_name       = module.acr_dns.name
  vnet_id             = module.vnet.id
}

# --- AI Foundry ---

module "foundry" {
  source = "../../modules/foundry"

  name                = "aide-d-msf"
  location            = "EastUS2"
  resource_group_name = module.ai-rg.name
  tags                = var.tags

  model_deployments = {
    "gpt-5.5" = {
      model_name    = "gpt-5.5"
      model_version = "2026-04-24"
      capacity      = 5004
    }
    "gpt-5.6-luna" = {
      model_name    = "gpt-5.6-luna"
      model_version = "2026-07-09"
      capacity      = 3007
    }
    "gpt-5.6-sol" = {
      model_name    = "gpt-5.6-sol"
      model_version = "2026-07-09"
      capacity      = 3990
    }
    "gpt-5.6-terra" = {
      model_name    = "gpt-5.6-terra"
      model_version = "2026-07-09"
      capacity      = 3003
    }
    "text-embedding-3-large" = {
      model_name    = "text-embedding-3-large"
      model_version = "1"
      capacity      = 12003
    }
  }
}

module "foundry_pe" {
  source = "../../modules/privateendpoint"

  name                = "aide-d-msf-pe"
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

module "ai_search" {
  source = "../../modules/aisearch"

  name                = "aide-d-srch01"
  location            = var.location
  resource_group_name = module.ai-rg.name
  sku                 = "basic"
  tags                = var.tags
}

module "search_pe" {
  source = "../../modules/privateendpoint"

  name                = "aide-d-srch01-pe"
  location            = var.location
  resource_group_name = module.ai-rg.name
  subnet_id           = module.subnet_private_endpoint.id
  resource_id         = module.ai_search.id
  subresource_names   = ["searchService"]

  private_dns_zone_ids = [
    module.search_dns.id
  ]
  tags = var.tags
}

# --- Container Registry ---

module "acr" {
  source = "../../modules/containerregistry"

  name                = "aidedevcr"
  location            = var.location
  resource_group_name = module.ai-rg.name
  sku                 = "Premium"
  tags                = var.tags
}

module "acr_pe" {
  source = "../../modules/privateendpoint"

  name                = "aidedevcr-pe"
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
