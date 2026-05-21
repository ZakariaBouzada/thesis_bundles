output "managed_identity_id" {
  description = "Resource ID of the User-Assigned Managed Identity (assigned to ACI)."
  value       = azurerm_user_assigned_identity.app.id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the Managed Identity (used for role assignments)."
  value       = azurerm_user_assigned_identity.app.principal_id
}

output "key_vault_id" {
  description = "Key Vault resource ID. Passed to the database module for secret storage."
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "Key Vault URI for secret retrieval."
  value       = azurerm_key_vault.main.vault_uri
}
