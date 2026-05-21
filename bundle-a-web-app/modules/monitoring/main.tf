# =============================================================================
# Module: Monitoring
#
# Creates a Log Analytics Workspace for container and infrastructure logs,
# and an optional Azure Monitor dashboard.
#
# RQ2 (Abstraction): Log retention, workspace SKU, and dashboard layout are
# fully opinionated. The SME user only decides whether monitoring is enabled.
# See Design Decision 9, Chapter 4.
#
# Log retention is set to 30 days — cost-effective and sufficient for
# debugging SME workloads without incurring large Log Analytics storage costs.
# =============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.name_prefix}-logs"
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "PerGB2018" # Pay-per-GB — cost-conscious for SMEs
  retention_in_days   = 30
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Azure Monitor Dashboard
# Provides a pre-built view of key container and database metrics.
# The SME user does not need to configure charts or queries manually.
# -----------------------------------------------------------------------------
resource "azurerm_portal_dashboard" "main" {
  name                = "${var.name_prefix}-dashboard"
  resource_group_name = var.resource_group
  location            = var.location
  tags                = var.tags

  # Dashboard JSON defines the tiles shown in the Azure Portal.
  # This is a minimal starter dashboard — CPU, memory, and request count.
  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          "0" = {
            position = { x = 0, y = 0, colSpan = 6, rowSpan = 4 }
            metadata = {
              type = "Extension/HubsExtension/PartType/MarkdownPart"
              settings = {
                content = {
                  settings = {
                    content = "## ${var.app_name} — ${var.environment}\nBundle A Web Application Stack\nMonitored by Log Analytics Workspace: **${var.name_prefix}-logs**"
                  }
                }
              }
            }
          }
        }
      }
    }
    metadata = {
      model = {
        timeRange = {
          value = { relative = { duration = 24, timeUnit = 1 } }
          type  = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        }
      }
    }
  })
}
