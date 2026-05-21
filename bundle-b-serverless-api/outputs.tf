# =============================================================================
# Bundle B — Outputs
# =============================================================================

output "api_url" {
  description = "Base URL of the API Gateway (use this as your API endpoint)"
  value       = module.apim.api_url
}

output "function_app_name" {
  description = "Name of the Function App (for function code deployment)"
  value       = module.functions.function_app_name
}

output "cosmos_db_endpoint" {
  description = "Cosmos DB account endpoint (SQL API)"
  value       = module.cosmosdb.endpoint
}

output "cosmos_db_database_name" {
  description = "Cosmos DB database name (default: 'api-db')"
  value       = module.cosmosdb.database_name
}

output "cosmos_db_container_name" {
  description = "Cosmos DB container name (default: 'items')"
  value       = module.cosmosdb.container_name
}

output "key_vault_id" {
  description = "Key Vault resource ID (for storing additional secrets)"
  value       = module.security.key_vault_id
}

output "resource_group_name" {
  description = "Azure Resource Group name containing all bundle resources"
  value       = azurerm_resource_group.main.name
}

output "deployment_summary" {
  description = "Human-readable summary of the deployment"
  value = <<-EOT
    =============================================
    Bundle B — Serverless API Backend
    =============================================
    Application : ${var.app_name}
    Environment : ${var.environment}
    Region      : ${var.location}
    Runtime     : ${var.functions_runtime}
    Rate Limit  : ${var.rate_limit_per_minute} calls/minute
    Monitoring  : ${var.enable_monitoring ? "enabled" : "disabled"}
    =============================================
    API URL     : ${module.apim.api_url}
    Function App: ${module.functions.function_app_name}
    Cosmos DB   : ${module.cosmosdb.endpoint}
    =============================================
    First deployment may take 30-45 minutes due to API Management provisioning.
    This is normal. Subsequent updates are faster.
    =============================================
  EOT
}