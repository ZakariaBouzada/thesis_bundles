# =============================================================================
# Module: API Management (Simplified for Consumption Tier)
#
# Creates API Management (Consumption tier) with API definition.
# Rate limiting and subscription keys are configured.
# Users and Products are NOT supported in Consumption tier.
#
# ⚠️ First deployment takes 30-45 minutes (Azure platform limitation).
# =============================================================================

# API Management (Consumption tier)
resource "azurerm_api_management" "main" {
  name                = "${var.name_prefix}-apim"
  location            = var.location
  resource_group_name = var.resource_group
  publisher_name      = "SME Bundle B"
  publisher_email     = "admin@${var.name_prefix}.example.com"
  sku_name            = "Consumption_0"  # Consumption tier (pay per call)
  tags                = var.tags
}

# API definition within API Management (Simplified — no import, manual definition)
resource "azurerm_api_management_api" "main" {
  name                = "${var.name_prefix}-api"
  resource_group_name = var.resource_group
  api_management_name = azurerm_api_management.main.name
  revision            = "1"
  display_name        = "${var.name_prefix} API"
  path                = "api"
  protocols           = ["https"]

  # Define a simple backend (the Function App URL)
  service_url = "https://${var.function_default_hostname}/api"
}

# Rate limiting policy (applied at API level)
resource "azurerm_api_management_api_policy" "rate_limit" {
  api_name            = azurerm_api_management_api.main.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <rate-limit calls="${var.rate_limit_per_minute}" renewal-period="60" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
XML
}

# Subscription key for API access (required for authentication)
# In Consumption tier, subscriptions are created automatically with a default key.
# We use the built-in "Master" subscription for simplicity.