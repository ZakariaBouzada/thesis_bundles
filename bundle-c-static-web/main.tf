# =============================================================================
# Bundle C — Static Web Application
# Root Module: Orchestration
#
# Architecture:
#   Browser → Azure Static Web Apps (global CDN, built-in HTTPS)
#                    → Application Insights (page view telemetry, optional)
#
# RQ2 (Modularisation): Bundle C uses only 3 modules compared to Bundle A (6)
# and Bundle B (6). This is intentional — the workload is simpler, so the
# bundle is simpler. The security and monitoring modules reuse the same
# patterns as Bundles A and B (Key Vault, Managed Identity, Application
# Insights), demonstrating that shared patterns persist across the complexity
# spectrum. See Chapter 4, Section 4.3.
#
# Key architectural decision: Azure Static Web Apps includes a global CDN,
# free SSL certificate, and custom domain support natively. There is no need
# for a separate CDN, load balancer, or certificate resource — the platform
# handles all of this. This is the most aggressive abstraction in the bundle
# suite and directly reflects the SME goal of minimum necessary configuration.
# =============================================================================
locals {
  name_prefix = "${var.app_name}-${var.environment}"

  # RQ2 (Modularisation): Identical tag structure across all three bundles.
  # Enables unified cost attribution and resource management in Azure Portal.
  common_tags = {
    Application = var.app_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Bundle      = "bundle-c-static-web"
  }
}

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Monitoring (created first — App Insights key needed by hosting)
# RQ2 (Modularisation): Same enable_monitoring pattern as Bundles A and B.
# Application Insights provides page view tracking and performance data
# without any configuration from the SME user.
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

# -----------------------------------------------------------------------------
# Module: Security
# RQ2 (Modularisation): Same Key Vault + Managed Identity pattern as
# Bundles A and B. Even a static website may need secrets (API keys for
# third-party services, deployment tokens). Consistent security model
# across all three bundles is a deliberate design choice.
# -----------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  name_prefix    = local.name_prefix
  location       = var.location
  resource_group = azurerm_resource_group.main.name
  tags           = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Hosting
# Azure Static Web Apps — global CDN, built-in HTTPS, custom domain support.
# This single module replaces: networking, load balancer, compute, CDN,
# and certificate management that would be required in a traditional stack.
# RQ2 (Abstraction): Maximum abstraction — the SME user specifies nothing
# about CDN configuration, SSL certificates, or global routing.
# -----------------------------------------------------------------------------
module "hosting" {
  source = "./modules/hosting"

  name_prefix                   = local.name_prefix
  location                      = var.location
  resource_group                = azurerm_resource_group.main.name
  environment                   = var.environment
  custom_domain                 = var.custom_domain
  key_vault_id                  = module.security.key_vault_id
  app_insights_instrumentation_key = var.enable_monitoring ? module.monitoring[0].app_insights_instrumentation_key : null
  app_insights_connection_string   = var.enable_monitoring ? module.monitoring[0].app_insights_connection_string : null
  tags                          = local.common_tags

  depends_on = [module.security, module.monitoring]
}
