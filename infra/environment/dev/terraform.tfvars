location            = "swedencentral"
resource_group_name = "rg-ctf-swd"
identity_name       = "workflow-ctf"
cloud_init_path     = "../../scripts/cloud-init.sh"

federated_subjects = {
  onapply = "repo:askri-7@247334802/CTFd-on-azure@1340879482:environment:dev"
}

tags = {
  env     = "dev"
  owner   = "ossec"
  product = "CTF platfrom"
}

naming = {
  project     = "CTF"
  environment = "dev"
}

storage_account_name = "terrastoraccount01"
address_space        = ["10.20.0.0/16"]

dynamic_subnets = {
  webapp = {
    cidr_block = "10.20.1.0/24"
    security_rules = [
      {
        name                       = "Allow-SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },

      {
        name                       = "Allow-Web"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "Allow-HTTPS"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  }
}


virtual_machine_vars = {
  size           = "Standard_B2als_v2"
  admin_username = "evil"
  computer_name  = "ctfd"
}

source_image = {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
}

os_disk = {
  caching              = "ReadWrite"
  storage_account_type = "Standard_LRS"
}

disks = {
  data = {
    storage_account_type          = "Standard_LRS"
    create_option                 = "Empty"
    disk_size_gb                  = 64
    lun                           = 0
    caching                       = "ReadWrite"
    public_network_access_enabled = false
  }
}