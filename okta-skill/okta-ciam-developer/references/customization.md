# Okta Customization — Domains, Branding, Email, Sign-In Widget

Derived from developer.okta.com: custom-url-domain, custom-email, custom-widget, terraform-manage-end-user-experience, terraform-manage-multiple-domains guides. Verified 2026-07-05.

## Contents

1. [Custom domain](#custom-domain)
2. [Issuer implications](#issuer-implications)
3. [Brands and themes](#brands-and-themes)
4. [Email customization](#email-customization)
5. [Sign-In Widget styling](#sign-in-widget-styling)
6. [Terraform mapping](#terraform-mapping)

## Custom domain

Replace `{org}.okta.com` with e.g. `login.example.com` for all end-user surfaces:

1. Add the domain (Admin Console → Customizations → Domain, or `okta_domain`).
2. Prove ownership via DNS TXT record; add a CNAME to the Okta-provided target.
3. Certificate: **Okta-managed** (Let's Encrypt, auto-renews — recommended) or bring your own cert (you own renewal, via `okta_domain_certificate`).
4. Multiple custom domains per org are supported (multi-brand): each domain maps to a **brand**.

## Issuer implications

- After adding a custom domain, tokens can be issued with `iss = https://login.example.com/...`.
- App/SDK config must use one consistent issuer; JWT validation compares `iss` **exactly**.
- Custom auth servers have an **issuer mode**: `ORG_URL`, `CUSTOM_URL`, or `DYNAMIC` (issuer follows the domain the request arrived on). With multiple domains, use `DYNAMIC` and make sure every validating API accepts the right issuer per audience.
- OIDC discovery works on the custom domain: `https://login.example.com/oauth2/default/.well-known/openid-configuration`.

## Brands and themes

- **Brand**: per-domain bundle of end-user experience settings — sign-in page, error pages, email templates, dashboard visibility settings.
- **Theme** (per brand): logo, favicon, primary/secondary colors, background for sign-in widget, dark-mode variants (newer orgs).
- Multi-brand CIAM: one org, several customer-facing brands — brand chosen by which custom domain the user hits.

## Email customization

- Templates (activation, password reset, MFA enrollment, etc.) are customizable per brand and per language, using Velocity-style variables (`${user.profile.firstName}`, `${resetPasswordLink}`...).
- **Custom email domain** (`okta_email_domain`): send from `no-reply@example.com` — requires SPF/DKIM DNS records that Okta provides; verify before activation.
- Keep the required dynamic variables in templates — Okta validates that links like the reset URL are present.

## Sign-In Widget styling

- **Hosted (redirect) widget — recommended**: customize via brand/theme + "Sign-in page code editor" (full HTML/CSS/JS control on paid orgs).
- The widget's current major generation ships from `okta/okta-signin-widget`; on OIE it renders flows driven entirely by your policies (authenticators, enrollment, recovery) — no widget code changes needed when policies change.
- **Embedded widget**: import `@okta/okta-signin-widget`, instantiate `new OktaSignIn({ issuer, clientId, redirectUri, useInteractionCodeFlow: true })`; you own hosting/CSP. Only choose embedded when redirect is impossible (deep UX control requirements).
- Style tokens: the widget exposes CSS variables/classes; prefer theme settings over deep CSS overrides (survives widget upgrades).

## Terraform mapping

```hcl
resource "okta_domain" "login" {
  name                    = "login.example.com"
  certificate_source_type = "OKTA_MANAGED"  # or "MANUAL"
}

resource "okta_domain_verification" "login" {
  domain_id = okta_domain.login.id
  # run after creating the TXT/CNAME records okta_domain reports
}

resource "okta_brand" "customer" {
  name = "Example Customer Brand"
  # link to domain via brand_id on okta_domain (see provider docs)
}

resource "okta_theme" "customer" {
  brand_id                          = okta_brand.customer.id
  logo                              = "assets/logo.png"
  primary_color_hex                 = "#0f62fe"
  secondary_color_hex               = "#393939"
  sign_in_page_touch_point_variant  = "BACKGROUND_IMAGE"
}

resource "okta_email_domain" "notify" {
  brand_id     = okta_brand.customer.id
  domain       = "mail.example.com"
  display_name = "Example"
  user_name    = "no-reply"
}
```

DNS steps (TXT/CNAME/SPF/DKIM) are external to Okta — pair with your DNS provider's Terraform provider for full automation. Example: `scripts/08-custom-domain-branding/`.
