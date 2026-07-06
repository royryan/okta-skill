# --- Provider access -----------------------------------------------------------
variable "okta_org_name" {
  type        = string
  description = "Okta org subdomain, e.g. dev-123456 (no -admin, no domain)"
}

variable "okta_base_url" {
  type        = string
  description = "okta.com | oktapreview.com | okta-emea.com"
  default     = "okta.com"
}

variable "okta_client_id" {
  type        = string
  description = "Client ID of the Terraform API Services app"
}

variable "okta_private_key" {
  type        = string
  sensitive   = true
  description = "PKCS#1 PEM private key (or file path) for the Terraform app"
}

variable "okta_scopes" {
  type        = list(string)
  description = "Scopes requested by the provider (must be granted on the app)"
  default = [
    "okta.groups.manage",
    "okta.apps.manage",
    "okta.policies.manage",
    "okta.authorizationServers.manage",
    "okta.trustedOrigins.manage",
    "okta.authenticators.manage",
  ]
}

# --- Tenant shape ----------------------------------------------------------------
variable "app_name" {
  type        = string
  description = "Human-readable product name used to label resources"
  default     = "Example App"
}

variable "environment" {
  type        = string
  description = "Environment tag: dev | staging | prod"
  default     = "dev"
}

variable "web_app_base_url" {
  type        = string
  description = "Base URL of the server-side web app"
  default     = "http://localhost:3000"
}

variable "spa_base_url" {
  type        = string
  description = "Base URL (origin) of the SPA"
  default     = "http://localhost:5173"
}

variable "api_audience" {
  type        = string
  description = "Audience for the custom authorization server"
  default     = "api://example"
}

variable "api_scopes" {
  type        = map(string) # name => description
  description = "Custom API scopes to define on the authorization server"
  default = {
    "app:read"  = "Read application data"
    "app:write" = "Write application data"
  }
}

variable "service_public_key_modulus" {
  type        = string
  description = "RSA public key modulus (n, base64url) for the M2M service integration JWKS"
  default     = null
}
