output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}

output "private_ip_address" {
  value = azurerm_network_interface.nic.private_ip_address
}

output "data_disk_ids" {
  value = { for name, disk in azurerm_managed_disk.data : name => disk.id }
}
