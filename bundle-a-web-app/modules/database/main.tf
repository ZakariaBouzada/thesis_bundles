# =============================================================================
# Module: Database
#
# Creates Azure Database for PostgreSQL Flexible Server and stores the
# auto-generated password in Key Vault.
#
# RQ2 (Abstraction): The SME user never sees or handles database credentials.
# The password is auto-generated, stored in Key Vault, and injected into
# the container via Managed Identity at runtime.
# See Design Decision 7, Chapter 4.
# =============================================================================

# -----------------------------------------------------------------------------
# Auto-generate a strong database password.
# The SME user never specifies this — it is created by the bundle.
# -----------------------------------------------------------------------------
resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# -----------------------------------------------------------------------------
# Store the password in Key Vault immediately.
# The plain-text value is only ever held in Terraform state and Key Vault.
# It is never written to outputs or environment variables by the bundle.
# -----------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "db_password" {
  name         = "${var.name_prefix}-db-password"
  value        = random_password.db.result
  key_vault_id = var.key_vault_id

  tags = var.tags
}

# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server
#
# RQ2 (Abstraction): Backup, high availability, and maintenance window
# settings are opinionated defaults hidden from the user. The SME only
# selects the SKU via db_instance_class.
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.name_prefix}-db"
  resource_group_name    = var.resource_group
  location               = var.location
  version                = "16"
  delegated_subnet_id    = var.db_subnet_id
  private_dns_zone_id    = var.private_dns_zone_id
  public_network_access_enabled = false
  administrator_login    = "app_user"
  administrator_password = random_password.db.result
  sku_name               = var.db_instance_class
  storage_mb             = 32768 # 32 GB minimum — sufficient for most SME apps
  zone                   = "1"

  # Automated backups with 7-day retention — hidden from user, always enabled.
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false # Cost control: geo-redundancy is expensive

  tags = var.tags


  lifecycle {
    # Prevent accidental password resets from destroying and recreating the server.
    ignore_changes = [administrator_password]
  }
}

# -----------------------------------------------------------------------------
# Default database — applications connect to this database.
# Fixed name "appdb" so the connection string is predictable.
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# -----------------------------------------------------------------------------
# Firewall rule: allow connections from within the VNet only.
# The database has no public endpoint — private subnet access only.
# No port 22 anywhere in this bundle.
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_firewall_rule" "vnet" {
  name             = "allow-vnet"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "10.0.0.0"
  end_ip_address   = "10.0.255.255"
}
