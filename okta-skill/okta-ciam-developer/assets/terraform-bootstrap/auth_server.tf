# Custom authorization server for the application's APIs:
# custom scopes, groups claim, and an access policy for the tenant's clients.

resource "okta_auth_server" "app" {
  name        = "${local.name_prefix}-auth-server"
  description = "Tokens for ${var.app_name} (${var.environment}) APIs"
  audiences   = [var.api_audience]
  issuer_mode = "ORG_URL" # switch to CUSTOM_URL/DYNAMIC when a custom domain exists
}

resource "okta_auth_server_scope" "api" {
  for_each = var.api_scopes

  auth_server_id   = okta_auth_server.app.id
  name             = each.key
  description      = each.value
  consent          = "IMPLICIT"
  metadata_publish = "ALL_CLIENTS"
}

# Groups claim, filtered to this tenant's groups to keep tokens small
resource "okta_auth_server_claim" "groups_access" {
  auth_server_id    = okta_auth_server.app.id
  name              = "groups"
  claim_type        = "RESOURCE"
  value_type        = "GROUPS"
  group_filter_type = "STARTS_WITH"
  value             = local.name_prefix
}

resource "okta_auth_server_claim" "groups_id" {
  auth_server_id    = okta_auth_server.app.id
  name              = "groups"
  claim_type        = "IDENTITY"
  value_type        = "GROUPS"
  group_filter_type = "STARTS_WITH"
  value             = local.name_prefix
}

# --- Access policy: which clients may get tokens, and token lifetimes ------------
resource "okta_auth_server_policy" "app_clients" {
  auth_server_id = okta_auth_server.app.id
  name           = "${local.name_prefix}-clients"
  description    = "Token issuance for ${var.app_name} clients"
  priority       = 1
  client_whitelist = compact([
    okta_app_oauth.web.client_id,
    okta_app_oauth.spa.client_id,
    var.service_public_key_modulus == null ? null : okta_app_oauth.service[0].client_id,
  ])
}

resource "okta_auth_server_policy_rule" "user_flows" {
  auth_server_id = okta_auth_server.app.id
  policy_id      = okta_auth_server_policy.app_clients.id
  name           = "user-flows"
  priority       = 1

  grant_type_whitelist = ["authorization_code"]
  scope_whitelist      = concat(["openid", "profile", "email", "offline_access"], keys(var.api_scopes))
  group_whitelist      = ["EVERYONE"]

  access_token_lifetime_minutes  = 60
  refresh_token_lifetime_minutes = 0        # 0 = unlimited window; rotation still applies
  refresh_token_window_minutes   = 10080    # 7 days idle window
}

resource "okta_auth_server_policy_rule" "m2m" {
  count = var.service_public_key_modulus == null ? 0 : 1

  auth_server_id = okta_auth_server.app.id
  policy_id      = okta_auth_server_policy.app_clients.id
  name           = "m2m"
  priority       = 2

  grant_type_whitelist = ["client_credentials"]
  scope_whitelist      = keys(var.api_scopes)
  group_whitelist      = ["EVERYONE"]

  access_token_lifetime_minutes = 60
}
