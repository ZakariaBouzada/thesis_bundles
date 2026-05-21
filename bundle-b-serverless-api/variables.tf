# =============================================================================
# Bundle B — Serverless API Backend
# User-facing parameters
# =============================================================================

variable "app_name" {
  description = "Application name used for resource naming (lowercase, alphanumeric, max 16 chars)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,14}[a-z0-9]$", var.app_name))
    error_message = "app_name must be lowercase alphanumeric, start and end with letter/number, max 16 characters."
  }
}

variable "environment" {
  description = <<-EOT
    Deployment environment (dev, staging, production).
    Affects resource naming and some configuration defaults.
  EOT
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be 'dev', 'staging', or 'production'."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "functions_runtime" {
  description = "Runtime stack for Azure Functions (node, python, dotnet)"
  type        = string
  default     = "node"

  validation {
    condition     = contains(["node", "python", "dotnet"], var.functions_runtime)
    error_message = "functions_runtime must be 'node', 'python', or 'dotnet'."
  }
}

variable "rate_limit_per_minute" {
  description = "API calls per minute per subscription key (rate limiting in API Management)"
  type        = number
  default     = 60

  validation {
    condition     = var.rate_limit_per_minute >= 10 && var.rate_limit_per_minute <= 1000
    error_message = "rate_limit_per_minute must be between 10 and 1000."
  }
}

variable "cosmos_db_max_throughput" {
  description = "Maximum RU/s for Cosmos DB autoscale (1000 RU/s minimum for serverless)"
  type        = number
  default     = 1000
}

variable "enable_monitoring" {
  description = "Create Application Insights dashboard for function monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}