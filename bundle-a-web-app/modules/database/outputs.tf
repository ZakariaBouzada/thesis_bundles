output "db_endpoint" {
  description = "PostgreSQL Flexible Server hostname for application connection strings."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "db_secret_id" {
  description = "Key Vault secret ID for the database password. Retrieve with: az keyvault secret show --id <value> --query value -o tsv"
  value       = azurerm_key_vault_secret.db_password.id
}

output "db_name" {
  description = "Database name to use in connection strings."
  value       = azurerm_postgresql_flexible_server_database.app.name
}

output "db_username" {
  description = "Database administrator username."
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}
