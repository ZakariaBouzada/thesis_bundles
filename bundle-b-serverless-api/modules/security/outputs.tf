output "managed_identity_id" {
  description = "Resource ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.main.id
}

output "managed_identity_client_id" {
  description = "Client ID of the Managed Identity (for Function App identity configuration)"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault (for secret references)"
  value       = azurerm_key_vault.main.vault_uri
}