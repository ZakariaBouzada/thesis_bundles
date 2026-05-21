# =============================================================================
# Module: Compute — Outputs
# =============================================================================

output "app_url" {
  description = "Public HTTPS URL of the Container App"
  value       = "https://${azurerm_container_app.app.latest_revision_fqdn}"
}

output "container_app_fqdn" {
  description = "Container App FQDN (without https://)"
  value       = azurerm_container_app.app.latest_revision_fqdn
}

output "container_app_id" {
  description = "Container App resource ID"
  value       = azurerm_container_app.app.id
}