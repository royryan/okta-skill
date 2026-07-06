# Custom scopes + groups claim on the default authorization server.
# Requires provider scope: okta.authorizationServers.manage

data "okta_auth_server" "default" {
  name = "default"
}

resource "okta_auth_server_scope" "orders_read" {
  auth_server_id   = data.okta_auth_server.default.id
  name             = "orders:read"
  description      = "Read orders"
  consent          = "IMPLICIT"
  metadata_publish = "ALL_CLIENTS"
}

resource "okta_auth_server_scope" "orders_write" {
  auth_server_id   = data.okta_auth_server.default.id
  name             = "orders:write"
  description      = "Create and modify orders"
  consent          = "IMPLICIT"
  metadata_publish = "ALL_CLIENTS"
}

# Groups claim on access tokens (filter to a prefix to keep tokens small)
resource "okta_auth_server_claim" "groups" {
  auth_server_id    = data.okta_auth_server.default.id
  name              = "groups"
  claim_type        = "RESOURCE" # access token; use "IDENTITY" for ID token
  value_type        = "GROUPS"
  group_filter_type = "STARTS_WITH"
  value             = "app-"
}
