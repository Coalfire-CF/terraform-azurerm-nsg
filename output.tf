output "network_security_group_id" {
  description = "Resource ID of the network security group."
  value       = azurerm_network_security_group.nsg.id
}

output "network_security_group_name" {
  description = "Name of the network security group."
  value       = azurerm_network_security_group.nsg.name
}
