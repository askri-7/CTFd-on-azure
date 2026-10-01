variable "subscription_id" {
  type        = string
  description = "Azure subscription ID used for deployment."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group for the deployment."
}

variable "storage_account_name" {
  type        = string
  description = "Existing storage account used for Terraform state."
}

variable "identity_name" {
  type        = string
  description = "Existing user-assigned identity used by GitHub Actions."
}

variable "location" {
  type        = string
  description = "Azure region for the VM and networking resources."
}
variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}
variable "cloud_init_path" {
  type        = string
  description = "Path to the cloud-init file, relative to the dev environment directory."
}

variable "federated_subjects" {
  type = map(string)
}

variable "tags" {
  type = map(string)
}

variable "naming" {
  type = object({
    project     = string
    environment = string
  })
}

variable "address_space" {
  type = list(string)
}

variable "ddos_protection_plan" {
  type = object({
    enable = bool
    id     = string
  })
  default = null
}

variable "dynamic_subnets" {
  type = map(object({
    cidr_block = string
    security_rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  }))
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key installed on the VM."
}

variable "ip_conf" {
  type = object({
    name       = string
    allocation = string
  })
  default = {
    name       = "internal"
    allocation = "Dynamic"
  }
}

variable "virtual_machine_vars" {
  type = object({
    size           = string
    admin_username = string
    computer_name  = string
  })
}

variable "source_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "os_disk" {
  type = object({
    caching              = string
    storage_account_type = string
  })
}

variable "boot_diagnostics" {
  type = object({
    enabled             = bool
    storage_account_uri = optional(string)
  })
  default = {
    enabled = false
  }
}

variable "disks" {
  type = map(object({
    storage_account_type          = string
    create_option                 = string
    disk_size_gb                  = number
    lun                           = number
    caching                       = string
    public_network_access_enabled = bool
  }))
}
