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

variable "functions_runtime" {
  description = "Runtime stack (node, python, dotnet)"
  type        = string
}

variable "managed_identity_id" {
  description = "User Assigned Managed Identity ID"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault resource ID (for RBAC or access policies)"
  type        = string
}

variable "cosmos_db_endpoint" {
  description = "Cosmos DB account endpoint"
  type        = string
}

variable "cosmos_db_key" {
  description = "Cosmos DB primary key (sensitive)"
  type        = string
  sensitive   = true
}

variable "cosmos_db_database" {
  description = "Cosmos DB database name"
  type        = string
}

variable "cosmos_db_container" {
  description = "Cosmos DB container name"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}