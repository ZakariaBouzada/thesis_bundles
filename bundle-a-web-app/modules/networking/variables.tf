variable "name_prefix"       { type = string }
variable "location"          { type = string }
variable "resource_group"    { type = string }
variable "nat_gateway_count" { type = number }
variable "environment"       { type = string }
variable "tags"              { type = map(string) }
