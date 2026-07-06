# Okta Core Concepts

Derived from developer.okta.com concept docs (How Okta Works, Okta Data Model, Authorization Servers, OAuth 2.0 and OIDC overview). Verified 2026-07-05.

## Contents

1. [The Okta data model](#the-okta-data-model)
2. [Identity Engine vs Classic Engine](#identity-engine-vs-classic-engine)
3. [Authorization servers: org vs custom](#authorization-servers-org-vs-custom)
4. [App integration types](#app-integration-types)
5. [Key endpoints](#key-endpoints)
6. [Tokens](#tokens)
7. [Okta domains and environments](#okta-domains-and-environments)

## The Okta data model

- **Org**: your tenant — a private Okta instance with its own URL (`https://{yourOrg}.okta.com`), users, and configuration. Everything below lives inside an org.
- **Universal Directory (UD)**: the user store. Every user has a **profile** (default + custom attributes defined by a **schema**) and a **status** lifecycle (`STAGED → PROVISIONED → ACTIVE → SUSPENDED/DEPROVISIONED`).
- **Groups**: flat collections of users, used for app assignment, policy targeting, and claims. **Group rules** auto-assign users to groups based on attribute expressions (Okta Expression Language).
- **App integrations (Applications)**: represent each application connected to the org — OIDC apps, SAML apps, API service apps, SCIM-provisioned apps. Users/groups are **assigned** to apps; assignment gates sign-in.
- **Policies**: rule sets evaluated at sign-in and enrollment — global session policy, authentication policies (per-app), authenticator enrollment, password policies. See `policies.md`.
- **Authorization servers**: mint OAuth/OIDC tokens. See below.
- **Identity Providers (IdPs)**: external login sources (social login — Google, Apple, Facebook; or enterprise SAML/OIDC IdPs) federated into Okta.
- **Authenticators**: credential types users enroll (password, Okta Verify, FIDO2/WebAuthn, phone, email, etc.).

## Identity Engine vs Classic Engine

- **Identity Engine (OIE)** is the current platform; all new orgs are OIE. Its pipeline is *assurance-based*: policies express required authenticator characteristics rather than fixed factor lists.
- **Classic Engine** persists for older orgs. SDK support, embedded-auth patterns, and policy semantics differ.
- All bundled guidance assumes OIE. If a user mentions `okta-auth-js` "authn flow", the Classic `/api/v1/authn` API, or their admin console lacks "Identity Engine" in the footer, they may be on Classic — flag it and note that developer.okta.com's default guides won't fully apply.

## Authorization servers: org vs custom

This distinction breaks more integrations than any other concept.

### Org authorization server
- Issuer: `https://{yourOrg}.okta.com` — endpoints under `/oauth2/v1/*`.
- Purpose: sign users in to Okta-managed resources (OIDC sign-in where you only need ID tokens), the **Okta management API** (`okta.*` scopes), and AI-agent ID-JAG issuance.
- **Its access tokens cannot be validated locally by your code** — they're consumable only by Okta's own APIs. You can validate the ID tokens it issues.
- Cannot add custom scopes or claims to access tokens.

### Custom authorization servers (API Access Management)
- Issuer: `https://{yourOrg}.okta.com/oauth2/{authServerId}` — every org gets one named **default**: `/oauth2/default`.
- Purpose: mint access tokens **for your own APIs** — custom scopes, custom claims, per-server access policies, audience (`aud`) you control.
- Access tokens are JWTs you validate locally (see `oidc-oauth-flows.md` §Token validation).
- Requires the API Access Management SKU on paid production orgs; included in Integrator Free Plan developer orgs.

**Rule of thumb:** signing users in only → org server is fine. Protecting your own API with scoped access tokens → custom authorization server, usually `default`.

## App integration types

| Type | Grant/flow | Typical stack | Client secret? |
|---|---|---|---|
| **Web Application** | Authorization Code (+ PKCE recommended) | Express, Flask, Spring Boot, ASP.NET Core | Yes (confidential client) |
| **Single-Page App (SPA)** | Authorization Code with PKCE (no secret) | React, Angular, Vue, vanilla JS | No (public client) |
| **Native Application** | Auth Code with PKCE (no secret) | iOS, Android, desktop | No |
| **API Services** | Client Credentials | Daemons, CI/CD, Terraform, backend services | Secret or (preferred) private-key JWT |

Implicit flow is deprecated — never recommend it. Resource Owner Password is deprecated on OIE.

## Key endpoints

For a custom auth server, prefix is `https://{org}.okta.com/oauth2/{id}`; for the org server, `https://{org}.okta.com/oauth2` (paths get `/v1/`):

- `GET /.well-known/openid-configuration` — OIDC discovery (also `/.well-known/oauth-authorization-server`)
- `GET /v1/authorize` — authorization endpoint (browser redirect)
- `POST /v1/token` — token endpoint (code exchange, client credentials, refresh, token exchange)
- `POST /v1/introspect` — remote token introspection
- `POST /v1/revoke` — token revocation
- `GET /v1/keys` — JWKS public keys for local JWT validation
- `GET /v1/userinfo` — OIDC userinfo
- `GET /v1/logout` — OIDC RP-initiated logout (`id_token_hint`, `post_logout_redirect_uri`)

Management API base: `https://{org}.okta.com/api/v1/...` (see `management-api.md`).

## Tokens

- **ID token**: JWT, describes *who signed in*, audience = your client ID. Consume in your app after validation; never send it to APIs as authorization.
- **Access token**: authorizes calls to an API (audience = the API). From a custom auth server it's a JWT you can validate locally; from the org server, treat as opaque.
- **Refresh token**: obtain with the `offline_access` scope. SPAs/native apps should use refresh-token rotation (default for those app types on OIE).
- Common claims: `iss`, `aud`, `sub`, `exp`, `iat`, `cid` (client ID), `scp` (scopes, access token), plus custom claims from the auth server.
- Access-token lifetime is set by the custom auth server's access policies (default 1 h); ID token 1 h; refresh lifetime/rotation configurable per policy.

## Okta domains and environments

- Base domains: `okta.com` (production), `oktapreview.com` (preview/sandbox), `okta-emea.com` (EU cell legacy).
- The admin console lives at `{org}-admin.okta.com` — **never** use the `-admin` host in app config, issuers, or Terraform `org_name`.
- **Custom domains** (e.g. `login.example.com`) front the org for end users; issuer selection ("Dynamic" issuer mode) matters when a custom domain exists — see `customization.md`.
- Developer/testing orgs: Okta **Integrator Free Plan** (signup at developer.okta.com/signup) — org names look like `dev-123456` or `trial-123456`.
