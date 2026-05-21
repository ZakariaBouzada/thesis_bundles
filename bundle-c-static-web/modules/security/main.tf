# =============================================================================
# Module: Security — Bundle C
#
# RQ2 (Modularisation): This module is structurally identical to the security
# modules in Bundles A and B. Key Vault + Managed Identity is a consistent
# security pattern across all three bundles regardless of workload type.
#
# For a static website this may seem like over-engineering, but it:
# 1. Stores the deployment token securely (never in plain text)
# 2. Provides a consistent security model for SMEs deploying multiple bundles
# 3. Allows future expansion (API keys, third-party service secrets)
#
# See Chapter 4, Section 4.3 (Cross-Bundle Shared Patterns).
# =============================================================================

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.name_prefix}-identity"
  location            = var.location
  resource_group_name = var.resource_group
  tags                = var.tags
}

resource "azurerm_key_vault" "main" {
  name                       = "${var.name_prefix}-kv"
  location                   = var.location
  resource_group_name        = var.resource_group
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = var.tags
}

# Terraform deployer access — needed to write the deployment token secret
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
}

# Managed Identity access — read-only for application use
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app.principal_id
  secret_permissions = ["Get", "List"]
}
