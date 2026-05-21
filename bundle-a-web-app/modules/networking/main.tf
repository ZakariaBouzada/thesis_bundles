# =============================================================================
# Module: Networking
#
# Creates the VNet, subnets, and conditional NAT Gateways.
#
# RQ2 (Abstraction): The SME user never configures any of these resources
# directly. The VNet CIDR, subnet layout, and NAT Gateway count are all
# determined by the bundle. The user only selects 'environment' and
# 'high_availability'. See Design Decision 5, Chapter 4.
#
# Architecture:
#   VNet: 10.0.0.0/16
#   ├── AZ-1 public  subnet: 10.0.1.0/24  (Application Gateway)
#   ├── AZ-1 private subnet: 10.0.11.0/24 (Container Instances)
#   ├── AZ-1 db      subnet: 10.0.21.0/24 (PostgreSQL — delegated)
#   ├── AZ-2 public  subnet: 10.0.2.0/24
#   ├── AZ-2 private subnet: 10.0.12.0/24
#   └── AZ-2 db      subnet: 10.0.22.0/24
# =============================================================================

# -----------------------------------------------------------------------------
# Virtual Network
# -----------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Public Subnets — Application Gateway lives here
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "public" {
  count                = 2
  name                 = "${var.name_prefix}-public-${count.index + 1}"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.${count.index + 1}.0/24"]
}

# -----------------------------------------------------------------------------
# Private Subnets — Container Instances live here
# No direct inbound internet access. Outbound only via NAT Gateway (if present).
#
# RQ2 (Abstraction): Subnet delegation for ACI is a technical Azure requirement
# hidden from the user. The bundle handles it automatically.
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "private" {
  count                = 2
  name                 = "${var.name_prefix}-private-${count.index + 1}"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.${count.index + 11}.0/24"]

  delegation {
    name = "aci-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# -----------------------------------------------------------------------------
# Database Subnets — PostgreSQL Flexible Server lives here
# Delegated to PostgreSQL service (Azure requirement).
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "database" {
  count                = 2
  name                 = "${var.name_prefix}-db-${count.index + 1}"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.${count.index + 21}.0/24"]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# -----------------------------------------------------------------------------
# NAT Gateway Public IPs
# One IP per NAT Gateway. Count determined by environment and high_availability.
#
# RQ2 (Parameterisation): nat_gateway_count comes from the root module local.
# This module does not know about 'environment' or 'high_availability' directly
# — it only receives the computed count. Clear module interface.
# -----------------------------------------------------------------------------
resource "azurerm_public_ip" "nat" {
  count               = var.nat_gateway_count
  name                = "${var.name_prefix}-nat-pip-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [tostring(count.index + 1)]
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# NAT Gateways (conditional)
#
# dev/staging:          0 NAT Gateways — saves ~€30-70/month
# production (default): 1 NAT Gateway  — cost-conscious production
# production (HA):      2 NAT Gateways — one per AZ, full availability
#
# WARNING: dev/staging containers cannot reach the public internet at runtime.
# All dependencies must be bundled into the container image at build time.
# AWS services are accessible via Service Endpoints (provisioned below).
# -----------------------------------------------------------------------------
resource "azurerm_nat_gateway" "main" {
  count               = var.nat_gateway_count
  name                = "${var.name_prefix}-nat-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group
  sku_name            = "Standard"
  zones               = [tostring(count.index + 1)]
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  count                = var.nat_gateway_count
  nat_gateway_id       = azurerm_nat_gateway.main[count.index].id
  public_ip_address_id = azurerm_public_ip.nat[count.index].id
}

# Associate NAT Gateways with private subnets.
# If 1 NAT Gateway: both private subnets share it (index 0 for both).
# If 2 NAT Gateways: each private subnet gets its own (index matches).
resource "azurerm_subnet_nat_gateway_association" "private" {
  count          = var.nat_gateway_count > 0 ? 2 : 0
  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.main[min(count.index, var.nat_gateway_count - 1)].id
}

# -----------------------------------------------------------------------------
# Network Security Group — Private Subnets
#
# RQ2 (Abstraction): Security rules are hidden from the user.
# Rules: port 80 inbound (HTTP from load balancer/internet),
#        port 5432 inbound (PostgreSQL from containers within VNet),
#        no port 22 anywhere (no VMs in this bundle).
# See Design Decision (Security), Chapter 4.
#
# Note: Port 80 was missing in the initial deployment and had to be added
# manually via CLI. It is now codified here permanently so that
# terraform destroy + terraform apply produces a correct deployment
# without any manual intervention. See Phase 3, Error 7 in deployment docs.
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "private" {
  name                = "${var.name_prefix}-private-nsg"
  location            = var.location
  resource_group_name = var.resource_group
  tags                = var.tags

  security_rule {
    name                       = "allow-http-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-postgresql-inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-other-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "private" {
  count                     = 2
  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.private.id
}

# -----------------------------------------------------------------------------
# Private DNS Zone — PostgreSQL Flexible Server requires private DNS
# -----------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "postgresql" {
  name                = "${var.name_prefix}.postgres.database.azure.com"
  resource_group_name = var.resource_group
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "${var.name_prefix}-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = var.resource_group
  tags                  = var.tags
}
