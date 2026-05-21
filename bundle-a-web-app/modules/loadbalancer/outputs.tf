output "app_gateway_fqdn" {
  description = "Public FQDN of the Load Balancer public IP."
  value       = azurerm_public_ip.lb.fqdn
}

output "app_gateway_ip" {
  description = "Public IP address of the Load Balancer."
  value       = azurerm_public_ip.lb.ip_address
}

output "backend_pool_id" {
  description = "Backend pool resource ID. Used by the compute module to register container IPs."
  value       = azurerm_lb_backend_address_pool.main.id
}

output "app_gateway_id" {
  description = "Load Balancer resource ID."
  value       = azurerm_lb.main.id
}
