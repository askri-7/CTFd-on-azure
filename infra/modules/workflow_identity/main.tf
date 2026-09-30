

resource "azurerm_role_assignment" "role" {
  for_each             = var.role_assignments
  principal_id         = var.workflow_identity_principal_id
  role_definition_name = each.value.role_name
  scope                = each.value.scope
}

resource "azurerm_federated_identity_credential" "cred" {
  for_each                  = var.federated_subjects
  name                      = each.key
  audience                  = [var.audience_name]
  issuer                    = var.issuer_url
  user_assigned_identity_id = var.user_assigned_identity_id
  subject                   = each.value
}