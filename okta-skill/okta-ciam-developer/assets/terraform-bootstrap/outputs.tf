output "issuer" {
  description = "OIDC issuer for all tenant clients and API validation"
  value       = okta_auth_server.app.issuer
}

output "audience" {
  value = var.api_audience
}

output "web_app_client_id" {
  value = okta_app_oauth.web.client_id
}

output "web_app_client_secret" {
  value     = okta_app_oauth.web.client_secret
  sensitive = true
}

output "spa_client_id" {
  value = okta_app_oauth.spa.client_id
}

output "service_client_id" {
  value = var.service_public_key_modulus == null ? null : okta_app_oauth.service[0].client_id
}

output "group_ids" {
  value = {
    users          = okta_group.users.id
    admins         = okta_group.admins.id
    high_assurance = okta_group.high_assurance.id
  }
}
