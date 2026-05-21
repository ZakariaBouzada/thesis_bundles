# =============================================================================
# Module: Networking (Simplified for Bundle B)
#
# Creates VNet, subnets, and Private DNS Zones for Cosmos DB.
# No NAT Gateways — Functions do not need outbound internet access.
# =============================================================================

# VNet
resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Private subnet for Cosmos DB private endpoint
resource "azurerm_subnet" "cosmos_db" {
  name                 = "${var.name_prefix}-cosmosdb-subnet"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private DNS Zone for Cosmos DB
resource "azurerm_private_dns_zone" "cosmos_db" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.resource_group
  tags                = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_db" {
  name                  = "${var.name_prefix}-cosmosdb-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_db.name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = var.resource_group
  tags                  = var.tags
}