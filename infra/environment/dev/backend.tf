terraform {
  backend "azurerm" {
    resource_group_name  = "rg-CTF-spc"
    storage_account_name = "terrastoraccount01"
    container_name       = "terratfstate"
    key                  = "terra-swd.tfstate"
    use_azuread_auth     = true
    use_oidc             = true
  }
}