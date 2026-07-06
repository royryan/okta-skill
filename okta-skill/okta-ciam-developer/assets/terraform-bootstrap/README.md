# Okta Tenant Bootstrap — Terraform Template

Ready-to-apply structure that bootstraps an Okta tenant for a CIAM application: groups, an OIDC web app + SPA, a service-app integration, a custom authorization server, and baseline policies. Derived from developer.okta.com Terraform guides and provider v6.x conventions.

## Prerequisites (one-time manual step)

Terraform needs its own access before it can manage anything — done in the Admin Console (see `references/terraform.md` for details):

1. Create an **API Services** app named e.g. "Terraform".
2. Assign an admin role (test: Organization Administrator / Super Admin).
3. Grant Okta API scopes: `okta.groups.manage`, `okta.apps.manage`, `okta.policies.manage`, `okta.authorizationServers.manage`, `okta.trustedOrigins.manage`, `okta.authenticators.manage`.
4. Client auth = Public key/Private key; generate a keypair; save the PEM (PKCS#1).

## Layout

```
terraform-bootstrap/
├── versions.tf          # provider requirement (okta/okta ~> 6.0)
├── providers.tf         # provider config (org, client_id, private key, scopes)
├── variables.tf         # all inputs
├── terraform.tfvars.example
├── groups.tf            # tenant groups
├── apps.tf              # OIDC web app + SPA + service integration + trusted origin
├── auth_server.tf       # custom authorization server, scopes, claims, access policy
├── policies.tf          # authentication policy, enrollment, password policy
└── outputs.tf           # client IDs, issuer, group IDs
```

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in org + credentials
terraform init
terraform plan
terraform apply
```

Outputs give you everything an app team needs: `issuer`, `web_app_client_id`, `spa_client_id`, `service_client_id`.

## Adapting

- Per-environment: copy this directory per org (dev/preview/prod), separate state.
- Add resource areas → add the matching `okta.*.manage` scope in BOTH the service app grant and `var.okta_scopes`.
- Big orgs: split apps/policies/directory into separate root modules to limit blast radius and rate-limit pressure.
