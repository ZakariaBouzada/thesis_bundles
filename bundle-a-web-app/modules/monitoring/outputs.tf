# workspace_id returns the full ARM resource ID — required by Container Apps Environment.
# Note: azurerm_log_analytics_workspace has two ID-like properties:
#   .id          = full ARM resource ID (/subscriptions/.../workspaces/name)  ← use this for Container Apps
#   .workspace_id = the GUID-only identifier                                  ← use this for direct API calls
output "workspace_id" {
  description = "Full ARM resource ID of the Log Analytics Workspace. Required by Container Apps Environment."
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_guid" {
  description = "Log Analytics Workspace GUID (short ID). Used for direct API/CLI queries."
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "workspace_key" {
  description = "Primary shared key. Sensitive — used internally only."
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}
