output "public_ip_address" {
  value = azurerm_public_ip.pip.ip_address
}

output "public_ip_id" {
  value = azurerm_public_ip.pip.id
}

output "subnet_ids" {
  value = { for name, subnet in azurerm_subnet.dynamic : name => subnet.id }
}
