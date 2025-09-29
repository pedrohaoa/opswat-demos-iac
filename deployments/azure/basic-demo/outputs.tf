output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.main.name
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.gateway.ip_address
}

output "application_gateway_url" {
  description = "URL to access MetaDefender Core through Application Gateway"
  value       = "http://${azurerm_public_ip.gateway.ip_address}"
}

output "metadefender_management_url" {
  description = "MetaDefender Core management interface URL"
  value       = "http://${azurerm_public_ip.gateway.ip_address}:8008"
}