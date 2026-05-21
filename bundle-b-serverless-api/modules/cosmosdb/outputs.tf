output "endpoint" {
  description = "Cosmos DB account endpoint (SQL API)"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "primary_key" {
  description = "Cosmos DB primary key (sensitive)"
  value       = azurerm_cosmosdb_account.main.primary_key
  sensitive   = true
}

output "database_name" {
  description = "Cosmos DB database name"
  value       = azurerm_cosmosdb_sql_database.main.name
}

output "container_name" {
  description = "Cosmos DB container name"
  value       = azurerm_cosmosdb_sql_container.main.name
}

output "account_id" {
  description = "Cosmos DB account resource ID"
  value       = azurerm_cosmosdb_account.main.id
}