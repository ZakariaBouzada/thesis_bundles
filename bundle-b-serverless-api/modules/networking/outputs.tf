output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "cosmos_db_subnet_id" {
  value = azurerm_subnet.cosmos_db.id
}

output "cosmos_db_private_dns_zone_id" {
  value = azurerm_private_dns_zone.cosmos_db.id
}