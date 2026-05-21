# =============================================================================
# Module: Hosting
#
# Creates Azure Static Web Apps with built-in global CDN and HTTPS.
#
# RQ2 (Abstraction): This single module encapsulates what would traditionally
# require separate resources for: web server, CDN configuration, SSL
# certificate provisioning, certificate renewal, and global routing.
# The SME user specifies nothing about any of these — the Azure platform
# handles all of it natively.
#
# RQ2 (Delimitation): Static Web Apps hosts static files (HTML, CSS, JS).
# It does not run server-side code (use Bundle A for containers,
# Bundle B for serverless APIs). See Section 1.7, Chapter 4.
#
# Pricing: Free tier — 100 GB bandwidth/month, 0.5 GB storage.
# Sufficient for most SME static websites at zero cost.
# =============================================================================

# -----------------------------------------------------------------------------
# Azure Static Web App — Free tier
# Built-in: global CDN, automatic HTTPS, custom domain SSL.
# The SME user gets all of this without any configuration.
# -----------------------------------------------------------------------------
resource "azurerm_static_web_app" "main" {
  name                = "${var.name_prefix}-swa"
  resource_group_name = var.resource_group
  location            = var.location
  sku_tier            = "Free"
  sku_size            = "Free"
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Custom Domain (conditional)
# RQ2 (Parameterisation): Only created when custom_domain is set.
# DNS CNAME validation is a post-deployment step documented in the README.
# -----------------------------------------------------------------------------
resource "azurerm_static_web_app_custom_domain" "main" {
  count             = var.custom_domain != null ? 1 : 0
  static_web_app_id = azurerm_static_web_app.main.id
  domain_name       = var.custom_domain
  validation_type   = "cname-delegation"
}

# -----------------------------------------------------------------------------
# Store deployment token in Key Vault
# The token allows CI/CD pipelines to publish site content.
# RQ2 (Abstraction): Same credential pattern as Bundles A and B —
# sensitive values never appear as plain text Terraform outputs.
# -----------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "deployment_token" {
  name         = "${var.name_prefix}-swa-token"
  value        = azurerm_static_web_app.main.api_key
  key_vault_id = var.key_vault_id
  tags         = var.tags
}

# -----------------------------------------------------------------------------
# Post-deployment note: Application Insights app settings
# azurerm_static_web_app does not yet expose an app_settings block in
# AzureRM v4. If enable_monitoring = true, add the instrumentation key
# after deployment with:
#
#   az staticwebapp appsettings set \
#     --name ${var.name_prefix}-swa \
#     --resource-group <rg-name> \
#     --setting-names APPINSIGHTS_INSTRUMENTATIONKEY=<key> \
#                     APPLICATIONINSIGHTS_CONNECTION_STRING=<string>
#
# This is the only post-deployment manual step in Bundle C.
# Documented as a delimitation in Section 1.7, Chapter 4.
# -----------------------------------------------------------------------------
