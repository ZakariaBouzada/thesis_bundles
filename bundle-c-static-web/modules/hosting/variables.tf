variable "name_prefix"    { type = string }
variable "location"       { type = string }
variable "resource_group" { type = string }
variable "environment"    { type = string }
variable "key_vault_id"   { type = string }
variable "tags"           { type = map(string) }

variable "custom_domain" {
  type    = string
  default = null
}

variable "app_insights_instrumentation_key" {
  type      = string
  default   = null
  sensitive = true
}

variable "app_insights_connection_string" {
  type      = string
  default   = null
  sensitive = true
}
