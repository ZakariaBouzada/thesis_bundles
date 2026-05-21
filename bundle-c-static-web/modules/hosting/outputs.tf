output "site_url" {
  description = "Public HTTPS URL of the static website."
  value       = "https://${azurerm_static_web_app.main.default_host_name}"
}

output "default_hostname" {
  description = "Default azurestaticapps.net hostname."
  value       = azurerm_static_web_app.main.default_host_name
}

output "deployment_token_secret_id" {
  description = "Key Vault secret ID for the deployment token. Use to deploy site content from CI/CD."
  value       = azurerm_key_vault_secret.deployment_token.id
}

output "custom_domain_verification_id" {
  description = "DNS TXT verification ID for custom domain validation."
  value       = azurerm_static_web_app.main.id
}

output "static_web_app_name" {
  description = "Static Web App resource name. Used in Azure CLI deploy commands."
  value       = azurerm_static_web_app.main.name
}
