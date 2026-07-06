# Tenant groups: users, admins, and a step-up group for sensitive access.

locals {
  name_prefix = lower(replace("${var.app_name}-${var.environment}", " ", "-"))
}

resource "okta_group" "users" {
  name        = "${local.name_prefix}-users"
  description = "${var.app_name} (${var.environment}) — standard users"
}

resource "okta_group" "admins" {
  name        = "${local.name_prefix}-admins"
  description = "${var.app_name} (${var.environment}) — administrators"
}

resource "okta_group" "high_assurance" {
  name        = "${local.name_prefix}-high-assurance"
  description = "${var.app_name} (${var.environment}) — step-up MFA required"
}
