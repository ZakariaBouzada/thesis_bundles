# =============================================================================
# Module: Cosmodb
#
# Creates Cosmos DB account (serverless mode), database, and container.
# Serverless mode means no provisioned throughput — pay only for RU consumed.
# =============================================================================

# Cosmos DB Account (Serverless)
resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.name_prefix}-cosmos"
  location            = var.location
  resource_group_name = var.resource_group
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"  # SQL API

  # Serverless capacity mode — no provisioned throughput cost
  capacity {
    total_throughput_limit = var.cosmos_db_max_throughput
  }

  consistency_policy {
    consistency_level = "Session"  # Good balance of consistency and performance
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # Enable private endpoint
  public_network_access_enabled = false

  tags = var.tags
}

# Private endpoint for Cosmos DB (secures access within VNet)
resource "azurerm_private_endpoint" "cosmos_db" {
  name                = "${var.name_prefix}-cosmos-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "cosmos-private-connection"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "cosmos-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = var.tags
}

# Database
resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "api-db"
  resource_group_name = var.resource_group
  account_name        = azurerm_cosmosdb_account.main.name
}

# Container (items)
resource "azurerm_cosmosdb_sql_container" "main" {
  name                  = "items"
  resource_group_name   = var.resource_group
  account_name          = azurerm_cosmosdb_account.main.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths    = ["/id"]  # Simple partition key for SME use cases
  partition_key_version = 1

  # Autoscale throughput (inherits from database if not specified)
  # No explicit throughput set — uses database-level autoscale
}