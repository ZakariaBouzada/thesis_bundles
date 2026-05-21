# =============================================================================
# Module: Monitoring — Bundle C
#
# Creates Application Insights for page view tracking and a Log Analytics
# Workspace as its backing store.
#
# RQ2 (Abstraction): The SME user does not configure sampling rates,
# retention policies, or alert rules. Bundle provides sensible defaults.
#
# For a static website, Application Insights provides:
# - Page view counts and unique visitor tracking
# - Page load performance metrics
# - JavaScript error tracking (when instrumentation key added to HTML)
# - Geographic distribution of visitors
#
# All of this is available to the SME user in the Azure Portal with
# zero configuration beyond enabling the module.
# =============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.name_prefix}-logs"
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = "${var.name_prefix}-insights"
  location            = var.location
  resource_group_name = var.resource_group
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}
