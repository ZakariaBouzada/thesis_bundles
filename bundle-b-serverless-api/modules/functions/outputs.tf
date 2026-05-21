output "function_app_id" {
  description = "Function App resource ID"
  value       = azurerm_linux_function_app.main.id
}

output "function_app_name" {
  description = "Function App name (for deployment)"
  value       = azurerm_linux_function_app.main.name
}

output "default_hostname" {
  description = "Default hostname of the Function App (used for API Management backend)"
  value       = azurerm_linux_function_app.main.default_hostname
}

output "application_insights_connection_string" {
  description = "Application Insights connection string (sensitive)"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}