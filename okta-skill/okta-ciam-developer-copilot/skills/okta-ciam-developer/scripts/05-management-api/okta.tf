# Automation identity: API Services app pre-granted okta.* scopes.
# Bootstrapping note: the FIRST such app (the one Terraform itself uses) must be
# created manually in the Admin Console. This resource creates ADDITIONAL
# automation identities once Terraform access exists.
# Requires provider scopes: okta.apps.manage + the scopes being granted.

resource "okta_app_oauth" "automation" {
  label                      = "User Lifecycle Automation"
  type                       = "service"
  grant_types                = ["client_credentials"]
  response_types             = ["token"]
  token_endpoint_auth_method = "private_key_jwt"

  jwks {
    kty = "RSA"
    kid = "automation-key-1"
    e   = "AQAB"
    n   = var.automation_public_key_modulus
  }
}

variable "automation_public_key_modulus" {
  type = string
}

# Grant management-API scopes to the app
resource "okta_app_oauth_api_scope" "automation_scopes" {
  app_id = okta_app_oauth.automation.id
  issuer = "https://${var.okta_org_name}.${var.okta_base_url}"
  scopes = [
    "okta.users.read",
    "okta.users.manage",
    "okta.groups.read",
    "okta.groups.manage",
  ]
}

variable "okta_org_name" { type = string }
variable "okta_base_url" {
  type    = string
  default = "okta.com"
}

# NOTE: admin-role assignment to apps is done in the Admin Console
# (Applications → app → Admin roles) or via the Role Assignment API;
# grant the narrowest custom role that covers these scopes.

output "automation_client_id" {
  value = okta_app_oauth.automation.client_id
}
