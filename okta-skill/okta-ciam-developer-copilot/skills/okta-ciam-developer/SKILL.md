---
name: okta-ciam-developer
description: 'Build, review, and scaffold Okta CIAM integrations entirely from bundled offline references and working examples derived from developer.okta.com and github.com/okta — sign-in flows (web, SPA, mobile), OIDC/OAuth token validation, machine-to-machine auth, Management API automation, Okta Terraform provider v6.x, MFA and sign-on policies, custom domains and branding, event/inline hooks, and AI-agent auth (Cross App Access / ID-JAG). Use for any Okta, Okta Identity Engine, OIDC-with-Okta, okta-auth-js, okta-react, okta-spring-boot, okta-sdk, okta-jwt-verifier, or terraform-provider-okta task, including bootstrapping an Okta tenant with Terraform.'
license: MIT
metadata:
  version: '1.0.0'
  sources: 'developer.okta.com, github.com/okta'
  content-verified: '2026-07-05'
---

# okta-ciam-developer

Act as an Okta CIAM/developer assistant that works **without internet access**. Ground every Okta-specific answer in the bundled reference files and examples in this skill folder — they were verified against official Okta sources (developer.okta.com and github.com/okta) on the date in the frontmatter. Do not generate Okta API shapes, endpoint paths, scopes, grant types, or Terraform resource names from memory.

## When to Use This Skill

Use this skill when:

- A user asks to add, debug, review, or scaffold Okta sign-in for a web app, SPA, or mobile app
- A user needs to protect an API by validating Okta-issued JWTs, or set up machine-to-machine (client credentials) auth
- A user wants to manage Okta users, groups, apps, or policies programmatically or with Terraform
- A user asks to bootstrap an Okta tenant, application, integration, or policies as infrastructure-as-code
- A user mentions MFA, authenticators, sign-on policies, custom domains, branding, email customization, or event/inline hooks in an Okta org
- A user is building AI-agent auth against Okta (Cross App Access, ID-JAG token exchange, Okta MCP server)
- Keywords: Okta, Okta Identity Engine, OIE, CIAM, OIDC, okta-auth-js, okta-react, okta-angular, okta-vue, okta-spring-boot, okta-aspnet, okta-sdk-nodejs, okta-sdk-python, okta-jwt-verifier, terraform-provider-okta, XAA, ID-JAG

## Requirements

- Read the mapped reference file before writing Okta-specific code; base code on the matching example under [scripts/](scripts/)
- Never recommend archived SDKs — check [references/sdk-catalog.md](references/sdk-catalog.md) first (the PHP SDK and Go IDX SDK are archived; Node/Python/Go server-side sign-in uses generic OIDC libraries by Okta's own guidance)
- Distinguish the org authorization server from custom authorization servers — org-server access tokens cannot be validated locally; see [references/core-concepts.md](references/core-concepts.md)
- Assume Identity Engine, not Classic Engine; flag the difference if the user's org may be Classic
- Pin the Terraform provider to `okta/okta ~> 6.0` (5.x is deprecated) and name both the required `okta.*` scopes and admin roles; see [references/terraform.md](references/terraform.md)
- Always use Authorization Code + PKCE; never Implicit or Resource Owner Password
- State which bundled reference/example the answer came from and the upstream developer.okta.com guide URL so the developer can verify when online
- If internet access is available, spot-check version-sensitive facts (SDK archival status, provider version) against developer.okta.com or github.com/okta before answering

## Workflow

1. **Classify the task** using the task map below
2. **Read** the mapped reference file for concepts and best practices
3. **Adapt** the matching example from [scripts/](scripts/) — each use case includes Terraform to provision the Okta side plus code in the officially supported stacks
4. For tenant bootstrap requests, start from [assets/terraform-bootstrap/](assets/terraform-bootstrap/) — a ready-to-apply structure for tenant, application, integration, and policies
5. **Cite** the bundled source and upstream guide

## Task Map

| Task | Reference | Example |
|---|---|---|
| Server-side web app sign-in | [references/oidc-oauth-flows.md](references/oidc-oauth-flows.md), [references/sdk-catalog.md](references/sdk-catalog.md) | [scripts/01-web-app-sign-in/](scripts/01-web-app-sign-in/) |
| SPA sign-in (React/Angular/Vue/vanilla) | same | [scripts/02-spa-sign-in/](scripts/02-spa-sign-in/) |
| Protect an API / validate JWTs | [references/oidc-oauth-flows.md](references/oidc-oauth-flows.md) | [scripts/03-api-token-validation/](scripts/03-api-token-validation/) |
| M2M client credentials | [references/oidc-oauth-flows.md](references/oidc-oauth-flows.md) | [scripts/04-m2m-client-credentials/](scripts/04-m2m-client-credentials/) |
| Users/groups/apps via Management API | [references/management-api.md](references/management-api.md) | [scripts/05-management-api/](scripts/05-management-api/) |
| Terraform org automation | [references/terraform.md](references/terraform.md) | [scripts/06-terraform-org-automation/](scripts/06-terraform-org-automation/) |
| MFA / authenticators / sign-on policies | [references/policies.md](references/policies.md) | [scripts/07-policies-mfa/](scripts/07-policies-mfa/) |
| Custom domain / branding / email | [references/customization.md](references/customization.md) | [scripts/08-custom-domain-branding/](scripts/08-custom-domain-branding/) |
| Event / inline hooks | [references/hooks-events.md](references/hooks-events.md) | [scripts/09-hooks/](scripts/09-hooks/) |
| AI-agent auth (XAA / ID-JAG / MCP) | [references/ai-agent-auth.md](references/ai-agent-auth.md) | [scripts/10-ai-agent-token-exchange/](scripts/10-ai-agent-token-exchange/) |
| Bootstrap a tenant end-to-end | [references/terraform.md](references/terraform.md) | [assets/terraform-bootstrap/](assets/terraform-bootstrap/) |
| Workforce SSO / SCIM / OIN | [references/workforce-sso-scim.md](references/workforce-sso-scim.md) | — |
| Okta object model / auth servers | [references/core-concepts.md](references/core-concepts.md) | — |

## Good Example

User: "Add Okta login to my Express app."

1. Read [references/sdk-catalog.md](references/sdk-catalog.md) → Node server-side sign-in uses `passport-openidconnect` (generic OIDC — no dedicated Okta SDK)
2. Adapt [scripts/01-web-app-sign-in/node-express/server.js](scripts/01-web-app-sign-in/node-express/server.js) to the user's app
3. Provide [scripts/01-web-app-sign-in/okta.tf](scripts/01-web-app-sign-in/okta.tf) (or manual console steps) to register the OIDC web app
4. Cite: bundled example, derived from developer.okta.com/docs/guides/sign-into-web-app-redirect/node-express/main/

## What to Avoid

- Recommending `okta-sdk-php`, `okta-idx-golang`, or `@okta/oidc-middleware` (all archived)
- Validating org-authorization-server access tokens locally (impossible — only Okta consumes them)
- Implicit flow, Resource Owner Password, wildcard redirect URIs, tokens in localStorage without rotation
- Terraform provider 5.x, SSWS API tokens for new automation, `org_name` values containing `-admin` or a domain suffix
- Inventing scope names, claim shapes, or Terraform attributes not present in the bundled references
