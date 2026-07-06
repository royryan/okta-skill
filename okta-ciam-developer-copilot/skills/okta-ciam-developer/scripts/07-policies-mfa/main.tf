# Authenticators + session + authentication (per-app) + enrollment policies.
# Scopes: okta.policies.manage, okta.authenticators.manage, okta.groups.read

# --- Authenticators (enable before referencing in policies) -------------------
resource "okta_authenticator" "webauthn" {
  name   = "FIDO2 (WebAuthn)"
  key    = "webauthn"
  status = "ACTIVE"
}

resource "okta_authenticator" "okta_verify" {
  name   = "Okta Verify"
  key    = "okta_verify"
  status = "ACTIVE"
  settings = jsonencode({
    channelBinding = { style = "NUMBER_CHALLENGE", required = "HIGH_RISK_ONLY" }
    compliance     = { fips = "OPTIONAL" }
    userVerification = "PREFERRED"
  })
}

data "okta_group" "everyone" {
  name = "Everyone"
}

# --- Global session policy -----------------------------------------------------
resource "okta_policy_signon" "baseline" {
  name            = "baseline-session"
  status          = "ACTIVE"
  description     = "Org-wide session baseline"
  groups_included = [data.okta_group.everyone.id]
}

resource "okta_policy_rule_signon" "baseline_allow" {
  policy_id          = okta_policy_signon.baseline.id
  name               = "allow-with-session-limits"
  status             = "ACTIVE"
  access             = "ALLOW"
  authtype           = "ANY"
  session_idle       = 120   # minutes
  session_lifetime   = 720
  session_persistent = false
}

# --- Per-app authentication policy (OIE assurance) ----------------------------
resource "okta_app_signon_policy" "two_factor" {
  name        = "any-two-factors"
  description = "Password/possession — any 2 factor types"
}

resource "okta_app_signon_policy_rule" "two_factor_rule" {
  policy_id                   = okta_app_signon_policy.two_factor.id
  name                        = "require-2fa"
  priority                    = 1
  access                      = "ALLOW"
  factor_mode                 = "2FA"
  re_authentication_frequency = "PT12H"
  constraints = [
    jsonencode({
      knowledge  = { types = ["password"], reauthenticateIn = "PT12H" }
      possession = { deviceBound = "REQUIRED" }
    })
  ]
}

# Step-up variant: phishing-resistant possession factor, re-auth every session
resource "okta_app_signon_policy" "phishing_resistant" {
  name        = "phishing-resistant-step-up"
  description = "WebAuthn-class factors for sensitive apps"
}

resource "okta_app_signon_policy_rule" "pr_rule" {
  policy_id                   = okta_app_signon_policy.phishing_resistant.id
  name                        = "require-phishing-resistant"
  priority                    = 1
  access                      = "ALLOW"
  factor_mode                 = "2FA"
  re_authentication_frequency = "PT0S" # every sign-in
  constraints = [
    jsonencode({
      possession = {
        phishingResistant = "REQUIRED"
        userPresence      = "REQUIRED"
      }
    })
  ]
}

# Attach to an app:
# resource "okta_app_oauth" "web_app" {
#   ...
#   authentication_policy = okta_app_signon_policy.two_factor.id
# }

# --- Authenticator enrollment policy ------------------------------------------
resource "okta_policy_mfa" "enrollment" {
  name            = "customer-enrollment"
  status          = "ACTIVE"
  description     = "What customers may/must enroll"
  is_oie          = true
  groups_included = [data.okta_group.everyone.id]

  okta_password  = { enroll = "REQUIRED" }
  okta_email     = { enroll = "REQUIRED" }
  fido_webauthn  = { enroll = "OPTIONAL" }
  okta_verify    = { enroll = "OPTIONAL" }
}

resource "okta_policy_rule_mfa" "enrollment_rule" {
  policy_id = okta_policy_mfa.enrollment.id
  name      = "enroll-at-sign-in"
  status    = "ACTIVE"
  enroll    = "LOGIN"
}

# --- Password policy ------------------------------------------------------------
resource "okta_policy_password" "customers" {
  name                   = "customer-password"
  status                 = "ACTIVE"
  description            = "Customer password rules"
  groups_included        = [data.okta_group.everyone.id]
  password_min_length    = 12
  password_history_count = 4
  password_max_lockout_attempts = 10
  password_auto_unlock_minutes  = 30
  recovery_email_token          = 60
  email_recovery                = "ACTIVE"
  question_recovery             = "INACTIVE" # security questions off
}
