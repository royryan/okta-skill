# Event hook + token inline hook registration.
# Scopes: okta.eventHooks.manage, okta.inlineHooks.manage

variable "hook_base_url" {
  type        = string
  description = "Public HTTPS base URL of your hook receiver"
  default     = "https://hooks.example.com"
}

variable "hook_shared_secret" {
  type      = string
  sensitive = true
}

resource "okta_event_hook" "user_lifecycle" {
  name = "user-lifecycle-events"
  events = [
    "user.lifecycle.create",
    "user.lifecycle.activate",
    "user.lifecycle.deactivate",
  ]
  channel = {
    type    = "HTTP"
    version = "1.0.0"
    uri     = "${var.hook_base_url}/okta/events"
  }
  auth = {
    type  = "HEADER"
    key   = "Authorization"
    value = var.hook_shared_secret
  }
  # Endpoint must answer the verification handshake at creation/activation time.
}

resource "okta_inline_hook" "token_enrichment" {
  name    = "token-enrichment"
  type    = "com.okta.oauth2.tokens.transform"
  version = "1.0.0"
  status  = "ACTIVE"
  channel = {
    type    = "HTTP"
    version = "1.0.0"
    uri     = "${var.hook_base_url}/okta/token-hook"
    method  = "POST"
  }
  auth = {
    type  = "HEADER"
    key   = "Authorization"
    value = var.hook_shared_secret
  }
}

# Wire the inline hook to a custom auth server by referencing it in the
# access policy rule (inline_hook_id) or via the auth server settings.
