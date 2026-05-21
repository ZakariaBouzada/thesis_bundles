# =============================================================================
# Bundle B — Serverless API Backend
# Root Module: Orchestration
#
# This bundle deploys:
#   - Azure Functions (serverless compute)
#   - Cosmos DB (NoSQL database)
#   - API Management (rate limiting, API keys)
#   - Key Vault (secrets) — reused pattern from Bundle A
#   - Managed Identity — reused pattern from Bundle A
# =============================================================================
# -----------------------------------------------------------------------------
# Provider configuration
# -----------------------------------------------------------------------------
provider "azurerm" {
  features {}
}
# -----------------------------------------------------------------------------
# Locals: shared computed values
# -----------------------------------------------------------------------------
locals {
  name_prefix = "${var.app_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Application = var.app_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Bundle      = "bundle-b-serverless-api"
  })
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Networking (Simplified — no NAT needed for Functions)
# Provides VNet and private subnets for Cosmos DB private endpoints.
# -----------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  name_prefix    = local.name_prefix
  location       = var.location
  resource_group = azurerm_resource_group.main.name
  tags           = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Security
# Creates Managed Identity and Key Vault (reused pattern from Bundle A)
# -----------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  name_prefix    = local.name_prefix
  location       = var.location
  resource_group = azurerm_resource_group.main.name
  tags           = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Cosmos DB
# Creates Cosmos DB account, database, and container (serverless mode)
# -----------------------------------------------------------------------------
module "cosmosdb" {
  source = "./modules/cosmosdb"

  name_prefix              = local.name_prefix
  location                 = var.location
  resource_group           = azurerm_resource_group.main.name
  cosmos_db_max_throughput = var.cosmos_db_max_throughput
  subnet_id                = module.networking.cosmos_db_subnet_id
  private_dns_zone_id      = module.networking.cosmos_db_private_dns_zone_id
  tags                     = local.common_tags

  depends_on = [module.networking]
}

# -----------------------------------------------------------------------------
# Module: Functions
# Creates Function App (Consumption plan), Storage Account
# -----------------------------------------------------------------------------
module "functions" {
  source = "./modules/functions"

  name_prefix          = local.name_prefix
  location             = var.location
  resource_group       = azurerm_resource_group.main.name
  functions_runtime    = var.functions_runtime
  managed_identity_id  = module.security.managed_identity_id
  key_vault_id         = module.security.key_vault_id
  cosmos_db_endpoint   = module.cosmosdb.endpoint
  cosmos_db_key        = module.cosmosdb.primary_key
  cosmos_db_database   = module.cosmosdb.database_name
  cosmos_db_container  = module.cosmosdb.container_name
  tags                 = local.common_tags

  depends_on = [module.security, module.cosmosdb]
}

# -----------------------------------------------------------------------------
# Module: API Management
# Creates API Management (Consumption tier) and defines the API
# -----------------------------------------------------------------------------
module "apim" {
  source = "./modules/apim"

  name_prefix            = local.name_prefix
  location               = var.location
  resource_group         = azurerm_resource_group.main.name
  function_app_id        = module.functions.function_app_id
  function_app_name      = module.functions.function_app_name
  function_default_hostname = module.functions.default_hostname
  rate_limit_per_minute  = var.rate_limit_per_minute
  tags                   = local.common_tags

  depends_on = [module.functions]
}

# -----------------------------------------------------------------------------
# Module: Monitoring (optional)
# Creates Application Insights dashboard
# -----------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.enable_monitoring ? 1 : 0

  name_prefix    = local.name_prefix
  location       = var.location
  resource_group = azurerm_resource_group.main.name
  tags           = local.common_tags
}