output "vnet_id" {
  description = "VNet resource ID."
  value       = azurerm_virtual_network.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (Application Gateway)."
  value       = azurerm_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (Container Instances)."
  value       = azurerm_subnet.private[*].id
}

output "db_subnet_id" {
  description = "Database subnet ID (PostgreSQL Flexible Server — AZ-1)."
  value       = azurerm_subnet.database[0].id
}

output "private_dns_zone_id" {
  description = "Private DNS Zone ID for PostgreSQL."
  value       = azurerm_private_dns_zone.postgresql.id
}
