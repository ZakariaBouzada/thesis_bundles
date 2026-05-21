# =============================================================================
# Module: Security
#
# Creates User Assigned Managed Identity and Key Vault.
# REUSED FROM BUNDLE A — identical code, no modifications needed.
# This demonstrates the reusability claim in RQ2.
# =============================================================================

# User Assigned Managed Identity (used by Functions to access Key Vault)
resource "azurerm_user_assigned_identity" "main" {
  name                = "${var.name_prefix}-identity"
  location            = var.location
  resource_group_name = var.resource_group
  tags                = var.tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "${var.name_prefix}-kv"
  location            = var.location
  resource_group_name = var.resource_group
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Purge protection disabled for development (enabled for production by default)
  purge_protection_enabled = false
  soft_delete_retention_days = 7

  tags = var.tags
}

# Data source for current client configuration (used for access policies)
data "azurerm_client_config" "current" {}

# Access policy for the Managed Identity (Function can read secrets)
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.main.principal_id

  secret_permissions = [
    "Get",
    "List",
  ]
}

# Access policy for Terraform (so it can create secrets during deployment)
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
  ]
}