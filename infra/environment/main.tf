data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_storage_account" "sta" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.rg.name
}
data "azurerm_user_assigned_identity" "msi" {

  name                = var.identity_name
  resource_group_name = var.resource_group_name

}

data "archive_file" "vite_dist" {
  type        = "zip"
  source_dir  = "${path.module}/../../../dist"
  output_path = "${path.module}/site.zip"
}

module "github_actions_identity" {
  source                         = "../../modules/workflow_identity"
  location                       = var.location
  resource_group_name            = data.azurerm_resource_group.rg.name
  workflow_identity_principal_id = data.azurerm_user_assigned_identity.msi.principal_id
  user_assigned_identity_id      = data.azurerm_user_assigned_identity.msi.id
  role_assignments = {

    deployment = {
      role_name = "Contributor"
      scope     = data.azurerm_resource_group.rg.id
    }

    terraform_state = {
      role_name = "Storage Blob Data Contributor"
      scope     = data.azurerm_storage_account.sta.id
    }

  }
  audience_name      = local.default_audience_name
  issuer_url         = local.github_issuer_url
  federated_subjects = var.federated_subjects
  tags               = var.tags
}