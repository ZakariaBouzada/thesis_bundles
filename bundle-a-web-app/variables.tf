# =============================================================================
# Bundle A — Web Application Stack
# Root Module: User-Facing Variables
#
# RQ2 (Parameterisation): These 10 variables are the ONLY decisions exposed
# to the SME user. Every other configuration decision is made by the bundle.
# Each variable corresponds to a choice the SME can reasonably make without
# cloud expertise. See Design Decision 11 in Chapter 4.
# =============================================================================

variable "app_name" {
  description = "Application name. Used in all Azure resource names (e.g. myapp-production-vnet). Must be lowercase, alphanumeric, and under 16 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,16}$", var.app_name))
    error_message = "app_name must be lowercase alphanumeric and 16 characters or fewer (Azure storage account name length constraint)."
  }
}

variable "environment" {
  description = "Deployment environment. Controls NAT Gateway configuration and cost. Use 'dev' or 'staging' for zero NAT Gateway cost, 'production' for a live workload."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

variable "high_availability" {
  description = "Deploy a NAT Gateway in each Availability Zone for true high availability. Only relevant when environment = 'production'. Adds approximately €30-40/month. Set to true for mission-critical applications."
  type        = bool
  default     = false
}

variable "instance_size" {
  description = "Compute size for container instances. Maps to Azure Container Instances CPU and memory. 'small' = 0.5 vCPU / 1 GB (dev/testing), 'medium' = 1 vCPU / 2 GB (low-traffic production), 'large' = 2 vCPU / 4 GB (moderate production traffic)."
  type        = string
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large"], var.instance_size)
    error_message = "instance_size must be one of: small, medium, large."
  }
}

variable "db_instance_class" {
  description = "PostgreSQL Flexible Server SKU. Controls database performance and cost. Defaults to the smallest burstable tier suitable for dev and low-traffic production."
  type        = string
  default     = "B_Standard_B1ms"

  validation {
    condition     = can(regex("^(B_Standard|GP_Standard|MO_Standard)_", var.db_instance_class))
    error_message = "db_instance_class must be a valid Azure PostgreSQL Flexible Server SKU (e.g. B_Standard_B1ms, GP_Standard_D2s_v3)."
  }
}

variable "container_image" {
  description = "Docker image to deploy. Use a public image (e.g. 'nginx:latest') for testing, or provide a full URL to an image in Azure Container Registry or another accessible registry."
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Port your container listens on. Must match the port your application code binds to."
  type        = number
  default     = 80

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be a valid port number between 1 and 65535."
  }
}

variable "enable_storage" {
  description = "Create an Azure Blob Storage account for static assets and file uploads. Disabled by default — enable only if your application needs to store files."
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Create a Log Analytics Workspace and monitoring dashboard. Enabled by default to ensure observability from day one."
  type        = bool
  default     = true
}

variable "location" {
  description = "Azure region for all resources. Defaults to Sweden Central, which is the closest region to Finland and the Nordic SME market."
  type        = string
  default     = "swedencentral"
}

variable "acknowledge_single_nat" {
  description = <<-EOT
    Required acknowledgement when environment = "production" and high_availability = false.
    Set to true to confirm you understand that a single NAT Gateway has no AZ redundancy.
    This forces a conscious decision rather than a silent default.
    Not required for dev/staging or when high_availability = true.
  EOT
  type    = bool
  default = false
}
