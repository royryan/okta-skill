# Provision the SPA app for use case 02.
# Requires provider scopes: okta.apps.manage, okta.trustedOrigins.manage

resource "okta_app_oauth" "spa" {
  label                      = "Example SPA"
  type                       = "browser"
  grant_types                = ["authorization_code", "refresh_token"]
  response_types             = ["code"]
  redirect_uris              = ["http://localhost:5173/login/callback"]
  post_logout_redirect_uris  = ["http://localhost:5173/"]
  token_endpoint_auth_method = "none" # public client — no secret
  pkce_required              = true
  refresh_token_rotation     = "ROTATE"
  refresh_token_leeway       = 30
}

resource "okta_trusted_origin" "spa_origin" {
  name   = "Example SPA (dev)"
  origin = "http://localhost:5173"
  scopes = ["CORS", "REDIRECT"]
}

output "spa_client_id" {
  value = okta_app_oauth.spa.client_id
}
