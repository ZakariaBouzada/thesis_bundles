variable "name_prefix" {
  description = "Prefix for resource names"
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

variable "function_app_id" {
  description = "Function App resource ID (for API backend)"
  type        = string
}

variable "function_app_name" {
  description = "Function App name"
  type        = string
}

variable "function_default_hostname" {
  description = "Function App default hostname"
  type        = string
}

variable "rate_limit_per_minute" {
  description = "Rate limit (calls per minute per subscription key)"
  type        = number
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}