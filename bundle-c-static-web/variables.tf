# =============================================================================
# Bundle C — Static Web Application
# Root Module: User-Facing Variables
#
# RQ2 (Parameterisation): Only 5 parameters exposed — the fewest of all three
# bundles. This demonstrates that simpler workloads produce simpler interfaces.
# The parameter reduction (Bundle A: 9, Bundle B: 7, Bundle C: 5) is a direct
# finding about how abstraction depth scales with workload complexity.
# See Chapter 4, Section 4.2 and Chapter 5 comparison table.
# =============================================================================

variable "app_name" {
  description = "Application name. Used in all Azure resource names (e.g. mysite-production). Must be lowercase, alphanumeric, max 16 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,16}$", var.app_name))
    error_message = "app_name must be lowercase alphanumeric and 16 characters or fewer."
  }
}

variable "environment" {
  description = "Deployment environment: dev, staging, or production."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

variable "location" {
  description = "Azure region for all resources. Defaults to West Europe — closest region to Finland and the Nordic SME market, that allows Azure static web apps. Note: Azure Static Web Apps is a global service; this location applies to companion resources only."
  type        = string
  default     = "westeurope"
}

variable "custom_domain" {
  description = "Optional custom domain for your website (e.g. 'www.mycompany.com'). Leave as null to use the default azurestaticapps.net URL. Requires DNS configuration after deployment — see README."
  type        = string
  default     = null
}

variable "enable_monitoring" {
  description = "Create Application Insights for page view tracking and performance monitoring. Recommended — leave enabled to understand how visitors use your site."
  type        = bool
  default     = true
}
