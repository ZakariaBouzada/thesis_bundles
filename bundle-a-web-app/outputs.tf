# =============================================================================
# Bundle A — Root Module Outputs
#
# These are the values the SME user needs after deployment.
# Sensitive values (passwords) are NEVER exposed here.
# The database secret ID allows retrieval via Azure CLI without
# exposing the credential itself.
# =============================================================================

output "app_url" {
  description = "Public HTTPS URL of your application. Open this in a browser to verify deployment."
  value       = module.compute.app_url
}

output "container_app_fqdn" {
  description = "Container App FQDN (without https://)."
  value       = module.compute.container_app_fqdn
}

output "database_endpoint" {
  description = "PostgreSQL Flexible Server hostname. Use this in your application's database connection string."
  value       = module.database.db_endpoint
}

output "database_secret_id" {
  description = <<-EOT
    Azure Key Vault secret ID containing the database credentials.
    Retrieve with:
      az keyvault secret show --id "<this value>" --query value -o tsv
    Never store the password in plain text or commit it to source control.
  EOT
  value       = module.database.db_secret_id
}

output "storage_account_name" {
  description = "Name of the Azure Blob Storage account for static assets. Only present when enable_storage = true."
  value       = var.enable_storage ? module.storage[0].storage_account_name : "Storage not enabled (set enable_storage = true)"
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for querying container and database logs. Only present when enable_monitoring = true."
  value       = var.enable_monitoring ? module.monitoring[0].workspace_id : "Monitoring not enabled (set enable_monitoring = true)"
}

output "resource_group_name" {
  description = "Azure Resource Group containing all bundle resources. Use this name to find resources in the Azure Portal."
  value       = azurerm_resource_group.main.name
}

output "deployment_summary" {
  description = "Human-readable summary of what was deployed and estimated monthly cost tier."
  value = <<-EOT
    =============================================
    Bundle A — Web Application Stack
    =============================================
    Application : ${var.app_name}
    Environment : ${var.environment}
    Region      : ${var.location}
    Compute     : ${var.instance_size} (${local.cpu_cores} vCPU / ${local.memory_in_gb} GB)
    Database    : ${var.db_instance_class}
    NAT Gateways: ${local.nat_gateway_count}
    Storage     : ${var.enable_storage ? "enabled" : "disabled"}
    Monitoring  : ${var.enable_monitoring ? "enabled" : "disabled"}
    =============================================
    App URL     : ${module.compute.app_url}
    DB Endpoint : ${module.database.db_endpoint}
    =============================================
  EOT
}
