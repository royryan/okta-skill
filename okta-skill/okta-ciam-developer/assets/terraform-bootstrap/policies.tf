# Baseline policies: per-app authentication policy (2FA), step-up policy,
# authenticator enrollment, and password policy.

data "okta_group" "everyone" {
  name = "Everyone"
}

# --- Authenticators ------------------------------------------------------------------
resource "okta_authenticator" "webauthn" {
  name   = "FIDO2 (WebAuthn)"
  key    = "webauthn"
  status = "ACTIVE"
}

# --- Authentication policy attached to the tenant's apps ------------------------------
resource "okta_app_signon_policy" "standard" {
  name        = "${local.name_prefix}-standard"
  description = "${var.app_name}: password + any second factor, 12h re-auth"
}

resource "okta_app_signon_policy_rule" "standard_2fa" {
  policy_id                   = okta_app_signon_policy.standard.id
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

# Step-up rule for the high-assurance group: phishing-resistant, every sign-in
resource "okta_app_signon_policy_rule" "step_up" {
  policy_id                   = okta_app_signon_policy.standard.id
  name                        = "high-assurance-step-up"
  priority                    = 0 # evaluated before the standard rule
  access                      = "ALLOW"
  factor_mode                 = "2FA"
  re_authentication_frequency = "PT0S"
  groups_included             = [okta_group.high_assurance.id]
  constraints = [
    jsonencode({
      possession = {
        phishingResistant = "REQUIRED"
        userPresence      = "REQUIRED"
      }
    })
  ]
}

# --- Authenticator enrollment ----------------------------------------------------------
resource "okta_policy_mfa" "enrollment" {
  name            = "${local.name_prefix}-enrollment"
  status          = "ACTIVE"
  description     = "${var.app_name}: enrollable authenticators"
  is_oie          = true
  groups_included = [data.okta_group.everyone.id]

  okta_password = { enroll = "REQUIRED" }
  okta_email    = { enroll = "REQUIRED" }
  fido_webauthn = { enroll = "OPTIONAL" }
  okta_verify   = { enroll = "OPTIONAL" }
}

resource "okta_policy_rule_mfa" "enrollment_rule" {
  policy_id = okta_policy_mfa.enrollment.id
  name      = "enroll-at-sign-in"
  status    = "ACTIVE"
  enroll    = "LOGIN"
}

# --- Password policy ---------------------------------------------------------------------
resource "okta_policy_password" "standard" {
  name                          = "${local.name_prefix}-password"
  status                        = "ACTIVE"
  description                   = "${var.app_name}: password requirements"
  groups_included               = [data.okta_group.everyone.id]
  password_min_length           = 12
  password_history_count        = 4
  password_max_lockout_attempts = 10
  password_auto_unlock_minutes  = 30
  email_recovery                = "ACTIVE"
  question_recovery             = "INACTIVE"
}
