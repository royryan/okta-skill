---
name: okta-ciam-developer
description: Offline-first Okta CIAM/developer toolkit — bundled reference docs, working code examples, and Terraform templates derived from developer.okta.com and github.com/okta, so no internet access is required. Covers sign-in flows (web, SPA, mobile), OIDC/OAuth token validation, machine-to-machine auth, Management API automation, Okta Terraform (provider v6.x), policies, custom domains/branding, hooks, and AI-agent auth (Cross App Access / ID-JAG). Use whenever the user mentions Okta, Okta Identity Engine, OIDC/OAuth with Okta, an Okta SDK (okta-auth-js, okta-react, okta-spring-boot, okta-sdk-python, okta-jwt-verifier-*, terraform-provider-okta), or asks to build, debug, review, or scaffold Okta sign-in, token validation, org automation, or tenant bootstrap code — even without naming a specific SDK.
license: MIT
metadata:
  version: 1.0.0
  sources: developer.okta.com, github.com/okta
  content-verified: 2026-07-05
---

# Okta CIAM Developer Skill

## Purpose and scope

This skill makes Claude an effective Okta developer assistant **without internet access**. Everything needed — SDK selection tables, API patterns, flow diagrams-in-prose, Terraform resource usage, and working code — is bundled in `references/`, `scripts/`, and `assets/`. All content was derived exclusively from official Okta sources (developer.okta.com and github.com/okta) and verified on the date in the frontmatter.

Primary scope: **CIAM (Customer Identity) and developer use cases**. Secondary: AI-agent auth and workforce (SSO/SCIM/OIN).

## Operating rules

1. **Ground answers in the bundled references, not memory.** Okta archives SDKs and restructures guidance frequently (the PHP SDK and Go IDX SDK are both archived). The bundled files were verified against live sources; raw training knowledge may be stale. Read the relevant reference file before generating Okta-specific code.
2. **If internet IS available**, treat the bundle as a starting point and spot-check anything version-sensitive (SDK archival status, provider version) against developer.okta.com or github.com/okta. If it is not available, say the answer is based on sources verified on the date above.
3. **Never invent Okta API shapes.** Endpoint paths, scopes, grant types, and Terraform resource names must come from the references or examples, not be guessed.
4. **Distinguish Identity Engine from Classic Engine.** All bundled guidance assumes Identity Engine (the default for all new orgs). If the user's org is Classic, flag that patterns differ.
5. **Distinguish the org authorization server from custom authorization servers.** Getting this wrong is the most common cause of broken token validation. See `references/core-concepts.md`.

## Workflow

1. **Classify the task** into one of the use cases below.
2. **Read the mapped reference file(s)** for concepts and best practices.
3. **Copy/adapt the matching example** from `scripts/` — these are complete, working patterns, each with its own Terraform to provision the Okta side.
4. For **tenant bootstrap** requests ("set up a new Okta org/app/policies with Terraform"), start from `assets/terraform-bootstrap/` — a ready-to-apply Terraform structure for tenant, application, integration, and policies.
5. **State the source** (which bundled reference/example, and the upstream Okta guide it was derived from) so the developer can verify when online.

## Task → resource map

| Task | Reference | Example |
|---|---|---|
| Server-side web app sign-in (Node, Python, Java, .NET, Go) | `references/oidc-oauth-flows.md`, `references/sdk-catalog.md` | `scripts/01-web-app-sign-in/` |
| SPA sign-in (React, Angular, Vue, vanilla JS) | same as above | `scripts/02-spa-sign-in/` |
| Protect an API / validate JWTs locally | `references/oidc-oauth-flows.md` §Token validation | `scripts/03-api-token-validation/` |
| Machine-to-machine (client credentials) | `references/oidc-oauth-flows.md` §Client credentials | `scripts/04-m2m-client-credentials/` |
| Manage users/groups/apps programmatically | `references/management-api.md` | `scripts/05-management-api/` |
| Automate the org with Terraform | `references/terraform.md` | `scripts/06-terraform-org-automation/` |
| MFA, authenticators, sign-on policies | `references/policies.md` | `scripts/07-policies-mfa/` |
| Custom domain, branding, email | `references/customization.md` | `scripts/08-custom-domain-branding/` |
| Event hooks / inline hooks | `references/hooks-events.md` | `scripts/09-hooks/` |
| AI-agent auth (XAA, ID-JAG, Okta MCP server) | `references/ai-agent-auth.md` | `scripts/10-ai-agent-token-exchange/` |
| Bootstrap a tenant end-to-end | `references/terraform.md` | `assets/terraform-bootstrap/` |
| Workforce SSO / SCIM / OIN (secondary) | `references/workforce-sso-scim.md` | — |
| Which SDK do I use? / Is X archived? | `references/sdk-catalog.md` | — |
| Okta object model, auth servers, OIE basics | `references/core-concepts.md` | — |

## Known traps (read before answering)

- **PHP**: no supported Okta SDK (`okta-sdk-php` archived). Recommend a generic OIDC library.
- **Go interactive sign-in**: `okta-idx-golang` and `samples-golang` archived. Use redirect auth with a standard OIDC library. Go Management SDK and JWT verifier remain active.
- **Node/Python/Go server-side sign-in**: Okta recommends generic OIDC libraries (passport-openidconnect, Flask + OIDC, Gorilla), not a dedicated Okta SDK.
- **Terraform provider**: use v6.x (`okta/okta`, `~> 6.0`); 5.x is deprecated. Provider auth should be an API Services app with OAuth 2.0 private-key JWT — org-wide API tokens are legacy.
- **Default authorization server** (`/oauth2/default`) requires the API Access Management SKU on production orgs; Integrator Free Plan orgs include it.
- **Access tokens from the org authorization server** (`/oauth2/v1/...`) are opaque-to-you: only Okta can validate them. Mint API access tokens from a custom authorization server if you need local JWT validation.

## Output expectations

- Code answers: working code following the bundled pattern + which example/reference it came from + the upstream developer.okta.com guide URL for later verification.
- Terraform answers: pin the provider, name required scopes AND admin roles for the service app, and warn about rate limits on large applies (see `references/terraform.md`).
- Conceptual answers: cite the bundled reference section; flag OIE vs Classic and org-vs-custom auth server wherever relevant.
