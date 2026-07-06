# API Services (service) app + auth server policy allowing client credentials.
# Requires provider scopes: okta.apps.manage, okta.authorizationServers.manage

resource "okta_app_oauth" "service" {
  label                      = "Orders Batch Service"
  type                       = "service"
  grant_types                = ["client_credentials"]
  response_types             = ["token"]
  token_endpoint_auth_method = "private_key_jwt"

  # Register the public key (JWKS) for private-key JWT auth
  jwks {
    kty = "RSA"
    kid = "service-key-1"
    e   = "AQAB"
    n   = var.service_public_key_modulus # base64url modulus of your RSA public key
  }
}

variable "service_public_key_modulus" {
  type        = string
  description = "RSA public key modulus (n) for the service app JWKS"
}

data "okta_auth_server" "default" {
  name = "default"
}

resource "okta_auth_server_policy" "m2m" {
  auth_server_id   = data.okta_auth_server.default.id
  name             = "m2m-clients"
  description      = "Client credentials for backend services"
  priority         = 1
  client_whitelist = [okta_app_oauth.service.client_id]
}

resource "okta_auth_server_policy_rule" "m2m_rule" {
  auth_server_id       = data.okta_auth_server.default.id
  policy_id            = okta_auth_server_policy.m2m.id
  name                 = "issue-tokens"
  priority             = 1
  grant_type_whitelist = ["client_credentials"]
  scope_whitelist      = ["orders:read", "orders:write"]
  group_whitelist      = ["EVERYONE"]
  access_token_lifetime_minutes = 60
}

output "service_client_id" {
  value = okta_app_oauth.service.client_id
}
