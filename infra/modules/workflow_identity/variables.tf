variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "resource_group_name" {
  type = string
}


variable "federated_subjects" {
  type = map(string)
}
variable "audience_name" {
  type = string
}
variable "issuer_url" {
  type = string
}
variable "role_assignments" {
  type = map(object({
    role_name = string
    scope     = string
  }))
}

variable "workflow_identity_principal_id" {
  type = string
}
variable "user_assigned_identity_id" {
  type = string
}
