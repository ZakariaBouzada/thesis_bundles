# =============================================================================
# Bundle A — Web Application Stack
# Root Module: Orchestration
#
# This file wires together all child modules. It is intentionally thin —
# business logic lives in the modules, not here.
#
# RQ2 (Modularisation): Each module has a single responsibility. Dependencies
# flow in one direction: networking → security → database/loadbalancer →
# compute → storage/monitoring. See Chapter 4, Section 4.1.
# =============================================================================

# -----------------------------------------------------------------------------
# Locals: shared computed values used across modules
# RQ2 (Abstraction): All naming, tagging, and size-mapping logic is centralised
# here so modules receive concrete values and do not need to re-derive them.
# -----------------------------------------------------------------------------
locals {
  # Naming prefix applied to every Azure resource.
  # Pattern: {app_name}-{environment} (e.g. myapp-production)
  name_prefix = "${var.app_name}-${var.environment}"

  # Standard tags applied to every resource in the bundle.
  # Enables cost tracking and resource attribution in the Azure portal.
  common_tags = {
    Application = var.app_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Bundle      = "bundle-a-web-app"
  }

  # RQ2 (Abstraction): Named size → Azure Container Instances CPU/memory mapping.
  # The SME user selects "small", "medium", or "large".
  # The bundle translates this into Azure-specific values.
  # See Design Decision 4, Chapter 4.
  instance_size_map = {
    small  = { cpu = 0.5, memory = 1.0 }
    medium = { cpu = 1.0, memory = 2.0 }
    large  = { cpu = 2.0, memory = 4.0 }
  }

  cpu_cores   = local.instance_size_map[var.instance_size].cpu
  memory_in_gb = local.instance_size_map[var.instance_size].memory

  # RQ2 (Parameterisation): NAT Gateway count derived from environment and
  # high_availability flag. The SME user never specifies a NAT count directly.
  # See Design Decision 5, Chapter 4.
  nat_gateway_count = (
    var.environment == "production" && var.high_availability == true  ? 2 :
    var.environment == "production" && var.high_availability == false ? 1 :
    0  # dev and staging: no NAT Gateway, eliminates ~€30-70/month cost
  )
}

# -----------------------------------------------------------------------------
# Precondition: Production + single NAT Gateway availability warning.
# RQ2 (Parameterisation): Surfaces a trade-off the SME user should consciously
# accept rather than discover during an outage. See Design Decision 5.
#
# The user must explicitly set acknowledge_single_nat = true in tfvars to
# proceed with production + high_availability = false. This forces a conscious
# decision rather than a silent default. See Chapter 4, Section 4.7.
# -----------------------------------------------------------------------------
resource "terraform_data" "ha_warning" {
  count = var.environment == "production" && var.high_availability == false ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.acknowledge_single_nat == true
      error_message = <<-EOT
        PRODUCTION RISK: You are deploying to production with high_availability = false.
        A single NAT Gateway will be deployed in Availability Zone 1 only.
        If AZ-1 fails, outbound internet connectivity from private subnets
        will be interrupted until the AZ recovers.

        To proceed, add this to your terraform.tfvars:
          acknowledge_single_nat = true

        To remove this risk entirely, set:
          high_availability = true  (adds approximately EUR 30-40/month)
      EOT
    }
  }
}

# -----------------------------------------------------------------------------
# Data: current Azure client configuration (used for Key Vault access policies)
# -----------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# Resource Group: single container for all bundle resources.
# One resource group per deployment enables clean teardown with one command.
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Networking
# Creates VNet, subnets, Internet Gateway, and conditional NAT Gateways.
# -----------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  name_prefix       = local.name_prefix
  location          = var.location
  resource_group    = azurerm_resource_group.main.name
  nat_gateway_count = local.nat_gateway_count
  environment       = var.environment
  tags              = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Security
# Creates Managed Identity for ACI and Key Vault access policies.
# -----------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  name_prefix    = local.name_prefix
  location       = var.location
  resource_group = azurerm_resource_group.main.name
  tags           = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Database
# Creates PostgreSQL Flexible Server and stores credentials in Key Vault.
# -----------------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  name_prefix       = local.name_prefix
  location          = var.location
  resource_group    = azurerm_resource_group.main.name
  db_instance_class = var.db_instance_class
  db_subnet_id      = module.networking.db_subnet_id
  private_dns_zone_id = module.networking.private_dns_zone_id
  key_vault_id      = module.security.key_vault_id
  tags              = local.common_tags

  depends_on = [module.networking, module.security]
}

# NOTE: loadbalancer module removed.
# Azure Container Apps provides a managed HTTP ingress controller natively.
# The SME user gets a public HTTPS URL without any load balancer configuration.
# See compute module and Chapter 4, Section 4.7 for the design decision.

# -----------------------------------------------------------------------------
# Module: Compute
# Creates Azure Container App with managed HTTP ingress.
# Replaces ACI + Load Balancer combination (ACI cannot be a LB backend target).
# See Phase 3, Error 6 in deployment documentation and Chapter 4, Section 4.7.
# -----------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group      = azurerm_resource_group.main.name
  container_image     = var.container_image
  container_port      = var.container_port
  cpu_cores           = local.cpu_cores
  memory_in_gb        = local.memory_in_gb
  managed_identity_id = module.security.managed_identity_id
  db_secret_id        = module.database.db_secret_id
  # Container Apps Environment requires Log Analytics — make monitoring mandatory
  # when compute is deployed. If enable_monitoring = false, create a minimal
  # workspace just for the environment (cost: negligible).
  log_analytics_workspace_id = var.enable_monitoring ? module.monitoring[0].workspace_id : azurerm_log_analytics_workspace.fallback[0].id
  tags                = local.common_tags

  depends_on = [module.security, module.database]
}

# Fallback Log Analytics Workspace when enable_monitoring = false.
# Container Apps Environment requires a workspace — this provides a minimal one.
resource "azurerm_log_analytics_workspace" "fallback" {
  count               = var.enable_monitoring ? 0 : 1
  name                = "${local.name_prefix}-logs-minimal"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Storage (conditional)
# RQ2 (Parameterisation): Only created when enable_storage = true.
# Avoids unnecessary resource sprawl for applications that do not need
# file storage. See Design Decision 8, Chapter 4.
# -----------------------------------------------------------------------------
module "storage" {
  source = "./modules/storage"
  count  = var.enable_storage ? 1 : 0

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group      = azurerm_resource_group.main.name
  managed_identity_id = module.security.managed_identity_id
  tags                = local.common_tags

  depends_on = [module.security]
}

# -----------------------------------------------------------------------------
# Module: Monitoring (conditional)
# RQ2 (Parameterisation): Dashboard only created when enable_monitoring = true.
# Log Analytics Workspace itself is always created when monitoring is enabled,
# so that compute logs have somewhere to go from day one.
# See Design Decision 9, Chapter 4.
# -----------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.enable_monitoring ? 1 : 0

  name_prefix    = local.name_prefix
  location       = var.location
  resource_group = azurerm_resource_group.main.name
  app_name       = var.app_name
  environment    = var.environment
  tags           = local.common_tags
}
