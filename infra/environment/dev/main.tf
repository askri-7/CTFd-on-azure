data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_storage_account" "sta" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.rg.name
}


module "vnet" {
  source                   = "../../modules/networking"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.location
  pip_name                 = "${var.naming.project}-${var.naming.environment}-pip"
  vnet_name                = "${var.naming.project}-${var.naming.environment}-vnet"
  virtual_network_location = var.location
  address_space            = var.address_space
  ddos_protection_plan     = var.ddos_protection_plan
  dynamic_subnets          = var.dynamic_subnets
  tags                     = var.tags
}

module "vm" {
  source = "../../modules/computing"

  vm_name             = "${var.naming.project}-${var.naming.environment}-vm"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ssh_public_key      = var.ssh_public_key

  ### custum config

  cloud_init = base64encode(templatefile(var.cloud_init_path, {
  cloudflare_api_token = var.cloudflare_api_token
}))



  ###  nic 

  nic_vars = {
    subnet_id = module.vnet.subnet_ids["webapp"]
    pub_ip_id = module.vnet.public_ip_id
  }

  ip_conf = var.ip_conf
  ## vm config
  virtual_machine_vars = var.virtual_machine_vars
  source_image         = var.source_image
  os_disk              = var.os_disk
  boot_diagnostics     = var.boot_diagnostics
  disks                = var.disks
  tags                 = var.tags

}


