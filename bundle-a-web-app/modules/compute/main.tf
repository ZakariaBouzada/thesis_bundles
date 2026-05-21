# =============================================================================
# Module: Compute
#
# Creates an Azure Container App running the user's container image.
#
# RQ2 (Abstraction): Switched from Azure Container Instances (ACI) to
# Azure Container Apps. ACI cannot integrate with Azure Load Balancer
# (discovered during Phase 3, Error 6). Container Apps provides a managed
# HTTP ingress controller natively — the SME user gets a working HTTPS URL
# without configuring any load balancer, certificates, or networking rules.
#
# This change also removes the entire loadbalancer/ module from the bundle —
# ingress is now handled internally by the Container Apps environment.
# See Chapter 4, Section 4.7 (Design Trade-offs).
#
# RQ2 (Delimitation): Bundle does not provision Azure Container Registry.
# User supplies a pre-built image URL. See Design Decision 10, Chapter 4.
# =============================================================================

# -----------------------------------------------------------------------------
# Container Apps Environment
# The managed environment handles networking, ingress, and log routing.
# One environment can host multiple Container Apps (not exposed to SME user).
# -----------------------------------------------------------------------------
resource "azurerm_container_app_environment" "main" {
  name                       = "${var.name_prefix}-cae"
  location                   = var.location
  resource_group_name        = var.resource_group
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.tags
}

# -----------------------------------------------------------------------------
# Container App
#
# RQ2 (Abstraction): The SME user specifies container_image, container_port,
# and instance_size. All Container Apps configuration (scaling rules, revision
# mode, ingress settings) is opinionated and hidden.
# -----------------------------------------------------------------------------
resource "azurerm_container_app" "app" {
  name                         = "${var.name_prefix}-app"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group
  revision_mode                = "Single"
  tags                         = var.tags

  # Managed Identity: authenticates to Key Vault and Storage without
  # credentials in environment variables.
  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  # Ingress: external HTTP access managed by Container Apps platform.
  # The SME user gets a working public URL with no load balancer config.
  ingress {
    external_enabled = true
    target_port      = var.container_port
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 1
    max_replicas = 3  # Basic auto-scaling: hidden from user, sensible default

    container {
      name   = "app"
      image  = var.container_image
      cpu    = var.cpu_cores
      memory = "${var.memory_in_gb}Gi"

      # DB secret location passed as environment variable.
      # Container reads actual password from Key Vault using Managed Identity.
      env {
        name  = "DB_SECRET_ID"
        value = var.db_secret_id
      }

      env {
        name  = "PORT"
        value = tostring(var.container_port)
      }
    }
  }
}
