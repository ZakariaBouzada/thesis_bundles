# =============================================================================
# Module: Functions
#
# Creates Azure Functions (Consumption plan), Storage Account (required for
# Functions runtime), and sets up environment variables for the function code
# to access Cosmos DB and Key Vault.
# =============================================================================

# Storage Account (required for Functions runtime)
resource "azurerm_storage_account" "main" {
  name                     = replace("${var.name_prefix}func", "-", "")
  location                 = var.location
  resource_group_name      = var.resource_group
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Application Insights (for function monitoring)
resource "azurerm_application_insights" "main" {
  name                = "${var.name_prefix}-insights"
  location            = var.location
  resource_group_name = var.resource_group
  application_type    = "web"
  tags                = var.tags
}

# Function App (Consumption plan)
resource "azurerm_linux_function_app" "main" {
  name                       = "${var.name_prefix}-func"
  location                   = var.location
  resource_group_name        = var.resource_group
  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  site_config {
    application_stack {
      node_version = var.functions_runtime == "node" ? "18" : null
      python_version = var.functions_runtime == "python" ? "3.11" : null
      dotnet_version = var.functions_runtime == "dotnet" ? "8.0" : null
    }
    cors {
      allowed_origins = ["*"]  # Allow all origins for API access
    }
  }

  app_settings = {
    # Application Insights
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string

    # Cosmos DB settings (function code reads these)
    "CosmosDbEndpoint"   = var.cosmos_db_endpoint
    "CosmosDbKey"        = var.cosmos_db_key
    "CosmosDbDatabase"   = var.cosmos_db_database
    "CosmosDbContainer"  = var.cosmos_db_container

    # Key Vault reference (function can read secrets at runtime via Managed Identity)
    "KeyVaultUri"        = "https://${var.name_prefix}-kv.vault.azure.net/"

    # Functions runtime settings
    "FUNCTIONS_EXTENSION_VERSION" = "~4"
    "FUNCTIONS_WORKER_RUNTIME"    = var.functions_runtime
  }

  tags = var.tags
}

# Service Plan (Consumption)
resource "azurerm_service_plan" "main" {
  name                = "${var.name_prefix}-asp"
  location            = var.location
  resource_group_name = var.resource_group
  os_type             = "Linux"
  sku_name            = "Y1"  # Consumption plan (pay per execution)
  tags                = var.tags
}