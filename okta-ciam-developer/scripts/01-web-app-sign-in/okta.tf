# Provision the OIDC Web App for use case 01.
# Requires provider scopes: okta.apps.manage, okta.groups.manage

resource "okta_app_oauth" "web_app" {
  label                      = "Example Web App"
  type                       = "web"
  grant_types                = ["authorization_code", "refresh_token"]
  response_types             = ["code"]
  redirect_uris              = ["http://localhost:3000/authorization-code/callback"]
  post_logout_redirect_uris  = ["http://localhost:3000/"]
  token_endpoint_auth_method = "client_secret_basic"
  pkce_required              = true
  consent_method             = "TRUSTED"
}

resource "okta_group" "web_app_users" {
  name        = "web-app-users"
  description = "Users allowed to sign in to Example Web App"
}

resource "okta_app_group_assignments" "web_app" {
  app_id = okta_app_oauth.web_app.id
  group {
    id = okta_group.web_app_users.id
  }
}

output "client_id" {
  value = okta_app_oauth.web_app.client_id
}

output "client_secret" {
  value     = okta_app_oauth.web_app.client_secret
  sensitive = true
}
