
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = var.ip_conf.name
    subnet_id                     = var.nic_vars.subnet_id
    private_ip_address_allocation = var.ip_conf.allocation
    public_ip_address_id          = var.nic_vars.pub_ip_id
  }
  tags = var.tags
}


resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.virtual_machine_vars.size
  admin_username      = var.virtual_machine_vars.admin_username
  computer_name       = var.virtual_machine_vars.computer_name
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  custom_data = var.cloud_init

  admin_ssh_key {
    username   = var.virtual_machine_vars.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
  }


  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }
  # optinal boot diag need a storage account stores boot screenshots and serial console logs for troubleshooting
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics.enabled ? [1] : []

    content {
      storage_account_uri = var.boot_diagnostics.storage_account_uri
    }
  }


  tags = var.tags
}



resource "azurerm_managed_disk" "data" {
  for_each                      = var.disks
  name                          = "${var.vm_name}-${each.key}-disk"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  storage_account_type          = each.value.storage_account_type
  create_option                 = each.value.create_option
  disk_size_gb                  = each.value.disk_size_gb
  public_network_access_enabled = each.value.public_network_access_enabled
  tags                          = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk-attachment" {
  for_each           = var.disks
  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = each.value.lun
  caching            = each.value.caching

}