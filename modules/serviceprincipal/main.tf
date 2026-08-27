resource "azuread_application" "this" {
  display_name = var.display_name
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
}

resource "time_rotating" "secret_rotation" {
  rotation_days = var.secret_validity_days
}

resource "azuread_application_password" "this" {
  application_id = azuread_application.this.id
  display_name   = "terraform-managed"
  end_date       = time_rotating.secret_rotation.rotation_rfc3339
}
