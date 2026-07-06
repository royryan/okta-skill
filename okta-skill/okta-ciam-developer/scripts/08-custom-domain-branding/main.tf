# Custom domain + brand + theme + custom email domain.
# Scopes: okta.domains.manage, okta.brands.manage, okta.templates.manage

# --- Custom domain --------------------------------------------------------------
resource "okta_domain" "login" {
  name                    = "login.example.com"
  certificate_source_type = "OKTA_MANAGED" # auto-provisioned & renewed cert
}

# After creating DNS records (see okta_domain.login.dns_records), verify:
resource "okta_domain_verification" "login" {
  domain_id = okta_domain.login.id
}

output "dns_records_to_create" {
  value = okta_domain.login.dns_records
}

# --- Brand + theme ---------------------------------------------------------------
data "okta_brands" "all" {}

# Use the default brand, or create okta_brand for multi-brand orgs
resource "okta_brand" "customer" {
  name   = "Example Customer Brand"
  locale = "en"
  # associate the custom domain with this brand in the domain settings
}

resource "okta_theme" "customer" {
  brand_id = okta_brand.customer.id

  logo    = "${path.module}/assets/logo.png"
  favicon = "${path.module}/assets/favicon.png"

  primary_color_hex   = "#0f62fe"
  secondary_color_hex = "#161616"

  sign_in_page_touch_point_variant       = "BACKGROUND_IMAGE"
  end_user_dashboard_touch_point_variant = "FULL_THEME"
  error_page_touch_point_variant         = "BACKGROUND_IMAGE"
  email_template_touch_point_variant     = "FULL_THEME"

  background_image = "${path.module}/assets/background.jpg"
}

# --- Custom email domain (no-reply@mail.example.com) ------------------------------
resource "okta_email_domain" "notify" {
  brand_id     = okta_brand.customer.id
  domain       = "mail.example.com"
  display_name = "Example"
  user_name    = "no-reply"
}

# okta_email_domain reports the SPF/DKIM records to create; verify afterward
# via okta_email_domain_verification (see provider docs).
