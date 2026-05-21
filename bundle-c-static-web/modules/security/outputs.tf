output "key_vault_id" {
  description = "Key Vault resource ID."
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "Key Vault URI."
  value       = azurerm_key_vault.main.vault_uri
}

output "managed_identity_id" {
  description = "Managed Identity resource ID."
  value       = azurerm_user_assigned_identity.app.id
}

output "managed_identity_principal_id" {
  description = "Managed Identity principal ID."
  value       = azurerm_user_assigned_identity.app.principal_id
}
