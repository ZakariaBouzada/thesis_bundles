# =============================================================================
# Module: Compute — Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group" {
  description = "Resource group name"
  type        = string
}

variable "container_image" {
  description = "Docker image to deploy"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "cpu_cores" {
  description = "CPU cores allocated to the container"
  type        = number
}

variable "memory_in_gb" {
  description = "Memory in GB allocated to the container"
  type        = number
}

variable "managed_identity_id" {
  description = "User Assigned Managed Identity ID for Key Vault access"
  type        = string
}

variable "db_secret_id" {
  description = "Key Vault secret ID for database credentials"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Container Apps Environment"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}