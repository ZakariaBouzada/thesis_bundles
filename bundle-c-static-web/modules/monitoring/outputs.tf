output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key. Add to your site's HTML for page view tracking."
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights connection string for SDK configuration."
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "workspace_id" {
  description = "Log Analytics Workspace full ARM resource ID."
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_guid" {
  description = "Log Analytics Workspace GUID for direct queries."
  value       = azurerm_log_analytics_workspace.main.workspace_id
}
