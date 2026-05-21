# =============================================================================
# Bundle C — Root Module Outputs
# =============================================================================

output "site_url" {
  description = "Public URL of your static website. Open in browser to verify deployment."
  value       = module.hosting.site_url
}

output "default_hostname" {
  description = "Default azurestaticapps.net hostname (always available, even with custom domain)."
  value       = module.hosting.default_hostname
}

output "deployment_token_secret_id" {
  description = <<-EOT
    Key Vault secret ID containing the Static Web Apps deployment token.
    Used by CI/CD pipelines to deploy your site content. Retrieve with:
      az keyvault secret show --id "<this value>" --query value -o tsv
  EOT
  value       = module.hosting.deployment_token_secret_id
}

output "custom_domain_verification" {
  description = "DNS TXT record value required to verify custom domain ownership. Only present when custom_domain is set."
  value       = var.custom_domain != null ? module.hosting.custom_domain_verification_id : "No custom domain configured"
}

output "resource_group_name" {
  description = "Azure Resource Group containing all bundle resources."
  value       = azurerm_resource_group.main.name
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key. Add to your site's JavaScript for telemetry. Only present when enable_monitoring = true."
  value       = var.enable_monitoring ? module.monitoring[0].app_insights_instrumentation_key : "Monitoring not enabled"
  sensitive   = true
}

output "deployment_summary" {
  description = "Human-readable deployment summary."
  value = <<-EOT
    =============================================
    Bundle C — Static Web Application
    =============================================
    Application  : ${var.app_name}
    Environment  : ${var.environment}
    Region       : ${var.location}
    Custom Domain: ${var.custom_domain != null ? var.custom_domain : "not configured"}
    Monitoring   : ${var.enable_monitoring ? "enabled" : "disabled"}
    =============================================
    Site URL     : ${module.hosting.site_url}
    =============================================
    NEXT STEP: Deploy your site content.

    Option 1 — Azure CLI (manual upload):
      az staticwebapp deploy \
        --name ${local.name_prefix}-swa \
        --resource-group ${local.name_prefix}-rg \
        --source ./your-site-folder

    Option 2 — GitHub Actions (automated):
      Add the deployment token from Key Vault as a GitHub secret
      named AZURE_STATIC_WEB_APPS_API_TOKEN, then push to your repo.
    =============================================
  EOT
}
