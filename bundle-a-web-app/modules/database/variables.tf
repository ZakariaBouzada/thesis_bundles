variable "name_prefix"       { type = string }
variable "location"          { type = string }
variable "resource_group"    { type = string }
variable "db_instance_class" { type = string }
variable "db_subnet_id"      { type = string }
variable "key_vault_id"      { type = string }
variable "tags"              { type = map(string) }
variable "private_dns_zone_id" {
  description = "ID of the Private DNS Zone for PostgreSQL"
  type        = string
}