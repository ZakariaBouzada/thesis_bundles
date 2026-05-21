# =============================================================================
# Module: Security
#
# Creates the Managed Identity used by Container Instances to access
# Key Vault and Storage without storing credentials in code.
# Also provisions the Key Vault itself.
#
# RQ2 (Abstraction): IAM/RBAC configuration is entirely hidden from the user.
# The SME user never creates role assignments, access policies, or managed
# identities manually. The bundle handles all identity plumbing.
# See Design Decision 7, Chapter 4.
#
# Note: No port 22 / SSH anywhere — there are no VMs in this bundle.
# =============================================================================

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# User-Assigned Managed Identity
# Assigned to Container Instances so they can authenticate to Azure services
# (Key Vault, Storage) without credentials in environment variables.
# -----------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.name_prefix}-identity"
  location            = var.location
  resource_group_name = var.resource_group
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Key Vault
# Stores the auto-generated database password. The SME user retrieves it
# via Azure CLI when needed — it is never exposed as a Terraform output.
#
# RQ2 (Abstraction): Credential lifecycle (generation, storage, access control)
# is fully managed by the bundle. See Design Decision 7, Chapter 4.
# -----------------------------------------------------------------------------
resource "azurerm_key_vault" "main" {
  name                = "${var.name_prefix}-kv"
  location            = var.location
  resource_group_name = var.resource_group
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Soft delete protects against accidental secret loss.
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # Allow destroy in thesis/dev context

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Key Vault Access Policy — Terraform deployer
# Allows Terraform to write the generated database password into Key Vault.
# -----------------------------------------------------------------------------
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
}

# -----------------------------------------------------------------------------
# Key Vault Access Policy — Managed Identity (Container Instances)
# Allows the ACI container to read the database password at runtime.
# Read-only: containers can Get and List secrets, not modify them.
# -----------------------------------------------------------------------------
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app.principal_id

  secret_permissions = ["Get", "List"]
}
