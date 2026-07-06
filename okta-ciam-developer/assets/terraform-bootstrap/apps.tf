# Applications: server-side web app, SPA, and an M2M service integration.

# --- Server-side web app (confidential client) -----------------------------------
resource "okta_app_oauth" "web" {
  label                      = "${var.app_name} Web (${var.environment})"
  type                       = "web"
  grant_types                = ["authorization_code", "refresh_token"]
  response_types             = ["code"]
  redirect_uris              = ["${var.web_app_base_url}/authorization-code/callback"]
  post_logout_redirect_uris  = ["${var.web_app_base_url}/"]
  token_endpoint_auth_method = "client_secret_basic"
  pkce_required              = true
  consent_method             = "TRUSTED"

  authentication_policy = okta_app_signon_policy.standard.id

  lifecycle {
    ignore_changes = [groups] # assignments managed below
  }
}

# --- SPA (public client) -----------------------------------------------------------
resource "okta_app_oauth" "spa" {
  label                      = "${var.app_name} SPA (${var.environment})"
  type                       = "browser"
  grant_types                = ["authorization_code", "refresh_token"]
  response_types             = ["code"]
  redirect_uris              = ["${var.spa_base_url}/login/callback"]
  post_logout_redirect_uris  = ["${var.spa_base_url}/"]
  token_endpoint_auth_method = "none"
  pkce_required              = true
  refresh_token_rotation     = "ROTATE"
  refresh_token_leeway       = 30

  authentication_policy = okta_app_signon_policy.standard.id
}

resource "okta_trusted_origin" "spa" {
  name   = "${var.app_name} SPA origin (${var.environment})"
  origin = var.spa_base_url
  scopes = ["CORS", "REDIRECT"]
}

# --- M2M service integration (optional — set service_public_key_modulus) ----------
resource "okta_app_oauth" "service" {
  count = var.service_public_key_modulus == null ? 0 : 1

  label                      = "${var.app_name} Service (${var.environment})"
  type                       = "service"
  grant_types                = ["client_credentials"]
  response_types             = ["token"]
  token_endpoint_auth_method = "private_key_jwt"

  jwks {
    kty = "RSA"
    kid = "${local.name_prefix}-service-key-1"
    e   = "AQAB"
    n   = var.service_public_key_modulus
  }
}

# --- Group assignments ---------------------------------------------------------------
resource "okta_app_group_assignments" "web" {
  app_id = okta_app_oauth.web.id
  group { id = okta_group.users.id }
  group { id = okta_group.admins.id }
}

resource "okta_app_group_assignments" "spa" {
  app_id = okta_app_oauth.spa.id
  group { id = okta_group.users.id }
  group { id = okta_group.admins.id }
}
