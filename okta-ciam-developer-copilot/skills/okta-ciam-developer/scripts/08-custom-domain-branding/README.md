# Use case 08 — Custom domain, branding, email (Terraform)

Pattern source: developer.okta.com custom-url-domain, custom-email, terraform-manage-end-user-experience, terraform-manage-multiple-domains guides. Concepts: `references/customization.md`.

## Files

- `main.tf` — custom domain (Okta-managed cert), brand, theme, email domain

## Sequence matters

1. Apply `okta_domain` → get DNS records from its outputs.
2. Create the TXT + CNAME records at your DNS provider (pair with a DNS Terraform provider to automate).
3. Apply `okta_domain_verification`.
4. Brand/theme/email domain afterward; email domain needs its own SPF/DKIM records + verification.

Issuer mode: with a custom domain, decide `CUSTOM_URL` vs `DYNAMIC` on your auth server and keep app configs consistent — token `iss` must match what your APIs validate.
