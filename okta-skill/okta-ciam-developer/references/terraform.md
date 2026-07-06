# Okta Terraform Provider — Setup and Best Practices

Derived from developer.okta.com Terraform guides (terraform-overview, terraform-enable-org-access, terraform-design-access-security, terraform-design-rate-limits, terraform-organize-configuration, terraform-import-existing-resources) and github.com/okta/terraform-provider-okta. Provider v6.x (v6.12.0, June 2026). Verified 2026-07-05.

## Contents

1. [Provider status and versioning](#provider-status-and-versioning)
2. [Enable Terraform access to an org](#enable-terraform-access-to-an-org)
3. [Provider configuration](#provider-configuration)
4. [Scopes and admin roles by resource area](#scopes-and-admin-roles-by-resource-area)
5. [Rate-limit strategy](#rate-limit-strategy)
6. [Organizing configuration](#organizing-configuration)
7. [Importing existing objects](#importing-existing-objects)
8. [Common resources cheat sheet](#common-resources-cheat-sheet)
9. [Gotchas](#gotchas)

## Provider status and versioning

- Source: `okta/okta`. **Use `~> 6.0`** — all 5.x versions are deprecated. v6.1.0+ adds Okta Governance API support. New provider code is built on the Terraform Plugin Framework and okta-sdk-golang v6.
- Docs: registry.terraform.io/providers/okta/okta/latest/docs; raw markdown in the repo's `docs/` (offline: see the cheat sheet below and the bundled templates).
- Every resource has example .tf files in the repo's `examples/` directory.

## Enable Terraform access to an org

The supported pattern is an **API Services app + OAuth 2.0 client credentials with private-key JWT** (not an SSWS API token):

1. Admin Console → Applications → Create App Integration → **API Services**. Name it (e.g. "Terraform").
2. **Admin roles tab** → assign a role covering what Terraform manages (test: Organization Administrator or Super Admin; production: a narrow custom role). Scopes alone are NOT enough.
3. **Okta API Scopes tab** → grant every scope your config needs (e.g. `okta.groups.manage`, `okta.apps.manage`, `okta.policies.manage`, `okta.authorizationServers.manage`, `okta.users.manage`, `okta.trustedOrigins.manage`, `okta.brands.manage`, `okta.domains.manage`, `okta.inlineHooks.manage`, `okta.eventHooks.manage`, `okta.schemas.manage`). Granting requires super admin.
4. **Client Credentials → Public key / Private key** → Add key → Generate (copy the PEM — shown once) or paste your own public key.
   - Private key must be **PKCS#1** (`-----BEGIN RSA PRIVATE KEY-----`). Convert if needed: `openssl rsa -in in.key -out out.pem -traditional`.
5. Store the private key in a secrets manager; feed it to Terraform via variable/env, never commit it.

## Provider configuration

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 6.0"
    }
  }
}

provider "okta" {
  org_name    = var.okta_org_name   # "dev-123456" — NO "-admin" suffix
  base_url    = var.okta_base_url   # "okta.com" | "oktapreview.com" | "okta-emea.com"
  client_id   = var.okta_client_id
  scopes      = var.okta_scopes     # must be a subset of scopes granted on the app
  private_key = var.okta_private_key # PEM contents or file path

  max_retries          = 5
  request_timeout      = 100
  # max_api_capacity   = 80  # optional: use only 80% of rate limit headroom
}
```

Env-var alternative: `OKTA_ORG_NAME`, `OKTA_BASE_URL`, `OKTA_API_CLIENT_ID`, `OKTA_API_SCOPES` (space-separated), `OKTA_API_PRIVATE_KEY` (or `OKTA_API_PRIVATE_KEY_ID`). Legacy `OKTA_API_TOKEN` (SSWS) still works but is discouraged.

## Scopes and admin roles by resource area

| Managing | Scope(s) | Notes |
|---|---|---|
| Groups, group rules | `okta.groups.manage` | |
| Users, user schema | `okta.users.manage`, `okta.schemas.manage` | |
| Apps (OIDC/SAML/service) | `okta.apps.manage` | |
| Policies (all types) | `okta.policies.manage` | |
| Custom auth servers | `okta.authorizationServers.manage` | |
| Trusted origins | `okta.trustedOrigins.manage` | |
| Brands/themes/email templates | `okta.brands.manage`, `okta.templates.manage` | |
| Custom domains | `okta.domains.manage` | |
| Hooks | `okta.eventHooks.manage`, `okta.inlineHooks.manage` | |
| Identity providers | `okta.idps.manage` | |
| Network zones | `okta.networkZones.manage` | |

Grant on the app AND list in the provider `scopes` argument. When you add a new resource type to your config, add its scope in both places (and check role permissions) or you'll get 400/403 errors mid-apply.

## Rate-limit strategy

Terraform can burn management-API rate limits fast on large configs:

- Set `max_retries` (provider waits on 429s using `X-Rate-Limit-Reset`).
- Use `max_api_capacity` (percentage) so Terraform leaves headroom for other org automation.
- Split giant states: separate workspaces/root modules per domain (users vs apps vs policies) so plans touch fewer endpoints.
- `terraform plan` itself reads heavily — avoid running many concurrent plans against one org.
- Prefer `okta_group_memberships` (bulk) over many `okta_group_membership`-style single resources; prefer group-based app assignment (`okta_app_group_assignments`) over per-user assignment.

## Organizing configuration

Recommended layout (mirrored by `assets/terraform-bootstrap/`):

```
envs/
  dev/ | prod/         # per-org root modules, separate state
modules/
  okta-app/            # reusable app + policy + assignment bundle
```

- One Okta org per environment (dev/preview/prod orgs), one state per org.
- Name resources by function; use `for_each` over maps for fleets of similar apps/groups.
- Keep secrets (private key) out of state inputs where possible; use env vars.

## Importing existing objects

- `terraform import okta_group.example {groupId}` — every resource doc lists its import ID form.
- Terraform ≥1.5: `import {}` blocks + `terraform plan -generate-config-out=generated.tf` to bulk-generate config for existing orgs.
- IDs come from the Admin Console URL or the management API (`GET /api/v1/groups?q=...`).

## Common resources cheat sheet

Directory & users: `okta_group`, `okta_group_rule`, `okta_group_memberships`, `okta_user`, `okta_user_schema_property`, `okta_group_schema_property`.
Apps: `okta_app_oauth` (OIDC web/SPA/native/service), `okta_app_saml`, `okta_app_bookmark`, `okta_app_group_assignments`, `okta_app_oauth_api_scope` (grant okta.* scopes to a service app), `okta_app_signon_policy`, `okta_app_signon_policy_rule`.
AuthZ servers: `okta_auth_server`, `okta_auth_server_scope`, `okta_auth_server_claim`, `okta_auth_server_policy`, `okta_auth_server_policy_rule`.
Org policies: `okta_policy_signon`, `okta_policy_rule_signon`, `okta_policy_mfa`, `okta_policy_rule_mfa`, `okta_policy_password`, `okta_policy_rule_password`, `okta_policy_profile_enrollment`, `okta_authenticator`.
Security/infra: `okta_network_zone`, `okta_trusted_origin`, `okta_event_hook`, `okta_inline_hook`, `okta_idp_oidc`, `okta_idp_saml`, `okta_idp_social`.
Branding: `okta_brand`, `okta_theme`, `okta_domain`, `okta_domain_verification`, `okta_domain_certificate`, `okta_email_domain`.
Data sources mirror most resources (`data "okta_group" ...`, `data "okta_policy" ...`, `data "okta_default_policy" ...`).

## Gotchas

- `org_name` is the subdomain only; including `.okta.com` or `-admin` is the #1 setup error.
- Deleting `okta_user` deactivates then deletes — irreversible; consider `lifecycle { prevent_destroy = true }` for real users.
- Default/system policies can't be created or destroyed — reference them with `data "okta_default_policy"` and add rules, or manage priority around them.
- `okta_app_oauth` for SPAs/native: set `token_endpoint_auth_method = "none"`, `pkce_required = true`.
- Changing immutable app fields (e.g. `type`) forces replacement — new client ID. Plan for credential rotation.
- Group memberships managed by group rules must not also be managed by Terraform membership resources (fight loop).
