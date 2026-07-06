# Groups, group rules, users, and app assignment.
# Provider config: see references/terraform.md or assets/terraform-bootstrap/.
# Scopes: okta.groups.manage, okta.users.manage, okta.apps.manage, okta.schemas.manage

# --- Groups (fleet via for_each) ---------------------------------------------
locals {
  groups = {
    "app-customers"  = "Customer-facing app users"
    "app-support"    = "Support staff"
    "app-admins"     = "Application administrators"
  }
}

resource "okta_group" "managed" {
  for_each    = local.groups
  name        = each.key
  description = each.value
}

# --- Group rule: auto-membership by attribute --------------------------------
resource "okta_group_rule" "support_by_dept" {
  name              = "support-by-department"
  status            = "ACTIVE"
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.department==\"Support\""
  group_assignments = [okta_group.managed["app-support"].id]
}

# --- Custom user schema attribute --------------------------------------------
resource "okta_user_schema_property" "tier" {
  index       = "customerTier"
  title       = "Customer Tier"
  type        = "string"
  master      = "OKTA"
  scope       = "NONE"
  enum        = ["free", "pro", "enterprise"]
  one_of {
    const = "free"
    title = "Free"
  }
  one_of {
    const = "pro"
    title = "Pro"
  }
  one_of {
    const = "enterprise"
    title = "Enterprise"
  }
}

# --- A service account user (real users usually come from registration/HR) ---
resource "okta_user" "svc_dashboard" {
  first_name = "Dashboard"
  last_name  = "Service"
  login      = "svc-dashboard@example.com"
  email      = "svc-dashboard@example.com"

  lifecycle {
    prevent_destroy = true # user deletion is irreversible
  }
}

# --- Assign groups to an existing app ----------------------------------------
data "okta_app" "web_app" {
  label = "Example Web App"
}

resource "okta_app_group_assignments" "web_app" {
  app_id = data.okta_app.web_app.id

  dynamic "group" {
    for_each = okta_group.managed
    content {
      id = group.value.id
    }
  }
}

# --- Importing existing objects (Terraform >= 1.5) ----------------------------
# import {
#   to = okta_group.existing_team
#   id = "00g1234567890abcdef"
# }
# Then: terraform plan -generate-config-out=generated.tf
