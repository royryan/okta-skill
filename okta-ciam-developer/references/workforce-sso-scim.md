# Workforce Use Cases — SSO, SCIM, OIN (Secondary Scope)

Derived from developer.okta.com OIN guides (oin-sso-overview, oin-lifecycle-mgmt-overview, submit-app-prereq) and SCIM docs. Verified 2026-07-05.

## Contents

1. [When this file applies](#when-this-file-applies)
2. [SSO into your app for Okta workforce customers](#sso-into-your-app-for-okta-workforce-customers)
3. [SCIM provisioning](#scim-provisioning)
4. [Okta Integration Network (OIN)](#okta-integration-network-oin)
5. [Inbound federation (enterprise IdPs into your CIAM org)](#inbound-federation)

## When this file applies

The primary scope of this skill is CIAM. Read this file when the user is: an ISV making their product "Okta-ready" for enterprise customers, publishing to the OIN, implementing SCIM, or federating enterprise IdPs into a CIAM org (B2B).

## SSO into your app for Okta workforce customers

Two protocol options; OIDC is recommended for new integrations:

- **OIDC**: your app is a standard OIDC relying party. For OIN publication, the integration must support **dynamic issuer** (each customer's org/custom domain) — configuration is per-tenant: issuer, client_id, client_secret. Use Authorization Code flow; SPAs use PKCE.
- **SAML 2.0**: your app is the SP; each customer's Okta org is the IdP. Support IdP-initiated and SP-initiated flows; consume `NameID` + attribute statements. Multi-tenant: per-customer IdP metadata upload.
- Test with an Integrator Free Plan org; Okta provides OIN submission testing tools (OIN Wizard in Admin Console).

## SCIM provisioning

Automate user lifecycle from Okta into your app (create/update/deactivate, group push):

- Implement a **SCIM 2.0 server** (`/scim/v2`): `/Users`, `/Groups`, `/ServiceProviderConfig`, `/ResourceTypes`, `/Schemas`.
- Required operations: GET (with `filter=userName eq "..."`, pagination `startIndex`/`count`), POST create, PUT/PATCH update, deactivate via `active: false` (soft delete; hard DELETE optional).
- Auth: OAuth 2.0 bearer (preferred) or header token, configured on the Okta side per customer.
- Matching: Okta matches on `userName` (and `externalId`); always return stable `id`s.
- Deactivation ≠ deletion: honor `active: false` — workforce customers expect offboarding to disable access immediately.
- Entitlements: newer OIN provisioning supports richer entitlements (roles/licenses) via SCIM extensions — check current OIN lifecycle docs when online.

## Okta Integration Network (OIN)

- Publishing gets your app into every workforce customer's app catalog with pre-built SSO/provisioning config.
- Path: build (OIDC/SAML and/or SCIM) → validate with OIN Wizard test plans → submit via the OIN Manager/Wizard → Okta review → publish.
- Requirements highlights: multi-tenant config (no hardcoded org URLs), no admin-credential collection, documented config guide for customers, support contact. Full checklist: /docs/guides/submit-app-prereq/.
- API service integrations (your service calls customers' Okta management APIs) are a separate OIN category using OAuth 2.0 + granted scopes, not SSWS tokens.

## Inbound federation

B2B CIAM pattern — customers' workforce IdPs sign in to *your* Okta org:

- Create an **Identity Provider** in your org per customer: `okta_idp_oidc` / `okta_idp_saml` (Terraform) or Admin Console.
- **Routing rules** (IdP discovery policy) send users to the right IdP by email domain/app/network.
- **JIT provisioning + profile mapping** create/update local users from IdP assertions; group assignment via IdP group sync or group rules on attributes.
- Account linking: configure match on email; consider restricting auto-linking for security.
