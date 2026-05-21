# =============================================================================
# Module: Storage (Conditional)
#
# Creates an Azure Blob Storage account for static assets and file uploads.
# Only instantiated when enable_storage = true in the root module.
#
# RQ2 (Parameterisation): The enable_storage flag follows the principle of
# minimum necessary resources. Storage is not created unless the user's
# application actually needs it. See Design Decision 8, Chapter 4.
# =============================================================================

resource "azurerm_storage_account" "main" {
  # Storage account names: max 24 chars, lowercase alphanumeric only.
  # Truncate name_prefix to stay within limit.
  name                     = substr(replace("${var.name_prefix}assets", "-", ""), 0, 24)
  resource_group_name      = var.resource_group
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally redundant — cost-conscious default for SMEs

  # Security defaults — no public blob access.
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  tags = var.tags
}

# Default container for application file uploads.
resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# RBAC: Grant the Managed Identity read/write access to blob storage.
# The container retrieves and stores files using its identity — no storage
# keys in environment variables.
# -----------------------------------------------------------------------------
resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.managed_identity_id
}
