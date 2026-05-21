output "api_url" {
  description = "Base URL of the API Gateway"
  value       = "${azurerm_api_management.main.gateway_url}/api"
}

output "api_management_name" {
  description = "API Management instance name"
  value       = azurerm_api_management.main.name
}

output "primary_key" {
  description = "Primary subscription key for API access (sensitive)"
  value       = "Use the subscription key from Azure Portal"
  sensitive   = true
}