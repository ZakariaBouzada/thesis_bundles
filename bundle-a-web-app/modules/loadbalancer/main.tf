# =============================================================================
# Module: Load Balancer
#
# Creates an Azure Standard Load Balancer for HTTP traffic routing.
#
# RQ2 (Delimitation): This module uses Azure Standard Load Balancer (Layer 4)
# rather than Application Gateway (Layer 7) as a cost-conscious choice for
# the thesis development environment. Monthly cost: ~€15-20 vs ~€130-160.
#
# Trade-off documented in Chapter 4, Section 4.7:
#   - Standard LB: TCP forwarding, no HTTP-aware health probes, no path routing
#   - Application Gateway: full HTTP routing, SSL termination, WAF support
#
# A production SME deployment should upgrade to Application Gateway.
# The module interface (inputs/outputs) is identical either way, so the swap
# requires only replacing this file — no changes to root main.tf or other
# modules. This is a direct demonstration of RQ2 (Modularisation).
# =============================================================================

# -----------------------------------------------------------------------------
# Public IP for the Load Balancer frontend
# -----------------------------------------------------------------------------
resource "azurerm_public_ip" "lb" {
  name                = "${var.name_prefix}-lb-pip"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Standard Load Balancer
# -----------------------------------------------------------------------------
resource "azurerm_lb" "main" {
  name                = "${var.name_prefix}-lb"
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

# -----------------------------------------------------------------------------
# Backend Pool — container IPs are registered here
# -----------------------------------------------------------------------------
resource "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.name_prefix}-backend-pool"
  loadbalancer_id = azurerm_lb.main.id
}

# -----------------------------------------------------------------------------
# Health Probe — TCP check on container port
# Layer 4 only: checks the TCP port is open, not HTTP response codes.
# -----------------------------------------------------------------------------
resource "azurerm_lb_probe" "http" {
  name                = "tcp-probe"
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = "Tcp"
  port                = var.container_port
  interval_in_seconds = 15
  number_of_probes    = 2
}

# -----------------------------------------------------------------------------
# Load Balancing Rule — forward port 80 to container port
# -----------------------------------------------------------------------------
resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = var.container_port
  frontend_ip_configuration_name = "frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.http.id
  idle_timeout_in_minutes        = 4
  floating_ip_enabled            = false
}
