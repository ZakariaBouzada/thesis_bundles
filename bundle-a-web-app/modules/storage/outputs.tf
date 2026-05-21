output "storage_account_name" {
  description = "Storage account name for use in application configuration."
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "Storage account resource ID."
  value       = azurerm_storage_account.main.id
}

output "uploads_container_name" {
  description = "Default blob container name for file uploads."
  value       = azurerm_storage_container.uploads.name
}
