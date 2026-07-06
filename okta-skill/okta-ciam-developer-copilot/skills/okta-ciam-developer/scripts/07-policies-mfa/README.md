# Use case 07 — MFA, authenticators, and sign-on policies (Terraform)

Pattern source: developer.okta.com configure-signon-policy guide + Policies concepts; resources per provider docs. Concepts and recipes: `references/policies.md`.

## Files

- `main.tf` — authenticators, global session policy, per-app authentication policy (password+ any-2FA, phishing-resistant step-up), enrollment policy

## Notes

- Enable an authenticator (`okta_authenticator`) before referencing it in policy rules.
- Authentication policies attach to apps via `authentication_policy` on `okta_app_oauth` — share one policy across many apps.
- Default/system policies can't be destroyed; use `data okta_default_policy` and rule priorities around them.
