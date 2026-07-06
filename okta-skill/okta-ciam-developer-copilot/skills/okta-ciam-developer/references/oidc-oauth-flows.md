# OIDC / OAuth 2.0 with Okta — Flows, Tokens, Validation

Derived from developer.okta.com guides: implement-grant-type, validate-access-tokens, validate-id-tokens, refresh-tokens, customize-tokens-*. Verified 2026-07-05.

## Contents

1. [Choosing a flow](#choosing-a-flow)
2. [Authorization Code + PKCE (walkthrough)](#authorization-code--pkce)
3. [Client Credentials (M2M)](#client-credentials-m2m)
4. [Refresh tokens](#refresh-tokens)
5. [Token validation](#token-validation)
6. [Custom scopes and claims](#custom-scopes-and-claims)
7. [Logout](#logout)
8. [Best practices checklist](#best-practices-checklist)

## Choosing a flow

| Client | Flow | Client auth |
|---|---|---|
| Server-side web app | Authorization Code (+ PKCE) | client secret (or private-key JWT) |
| SPA | Authorization Code with PKCE | none (public client) |
| Native/mobile | Authorization Code with PKCE | none |
| Service/daemon/CI | Client Credentials | private-key JWT (preferred) or secret |
| AI agent acting for a user | Token Exchange (ID-JAG / XAA) | private-key JWT — see `ai-agent-auth.md` |
| Device without browser | Device Authorization Grant | none |

Deprecated — never use: Implicit, Resource Owner Password.

## Authorization Code + PKCE

Issuer below = your authorization server (`https://{org}.okta.com/oauth2/default` for the default custom server; org server uses `/oauth2/v1/*`).

1. Generate `code_verifier` (43–128 char random string), derive `code_challenge = BASE64URL(SHA256(verifier))`.
2. Redirect the browser to `{issuer}/v1/authorize` with:
   - `client_id`, `response_type=code`, `scope=openid profile email` (add `offline_access` for refresh)
   - `redirect_uri` (must exactly match one registered on the app)
   - `state` (CSRF protection — random, verified on return)
   - `code_challenge`, `code_challenge_method=S256`
3. Okta authenticates the user per policy, redirects back with `?code=...&state=...`.
4. Exchange the code — `POST {issuer}/v1/token`, `application/x-www-form-urlencoded`:
   `grant_type=authorization_code&code=...&redirect_uri=...&code_verifier=...` + client auth (secret via Basic auth/POST body for confidential clients; `client_id` alone for public clients).
5. Response: `access_token`, `id_token`, optionally `refresh_token`, `expires_in`.
6. Validate the ID token (below) before establishing a session.

The bundled examples in `scripts/01-web-app-sign-in/` and `scripts/02-spa-sign-in/` implement this via SDKs — prefer SDKs to hand-rolled flows.

## Client Credentials (M2M)

For service apps calling your API (custom auth server) or the Okta management API (org auth server, `okta.*` scopes).

- App type: **API Services**.
- Request: `POST {issuer}/v1/token` with `grant_type=client_credentials&scope=...`.
- Client auth options:
  - `client_secret_basic` / `client_secret_post` — simple, weaker.
  - **`private_key_jwt` (recommended)**: register a public key (JWKS) on the app; send `client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer` and a `client_assertion` JWT signed with the private key (claims: `iss`=`sub`=client_id, `aud`={issuer}/v1/token, `exp` short). Required pattern for Terraform and Okta management-API service apps at scale; also supports DPoP where enabled.
- Custom auth servers need the scope defined first (Admin Console → Security → API → your server → Scopes, or `okta_auth_server_scope` in Terraform).
- No refresh tokens for client credentials — just request a new token.

See `scripts/04-m2m-client-credentials/`.

## Refresh tokens

- Request the `offline_access` scope during sign-in.
- SPAs and native apps get **refresh token rotation** by default: each refresh returns a new refresh token and invalidates the old (grace period configurable).
- Web apps (confidential) may use persistent refresh tokens; lifetime set in the auth server access policy rule.
- Refresh: `POST {issuer}/v1/token` with `grant_type=refresh_token&refresh_token=...&scope=...` (scope optional/narrowing) + client auth.

## Token validation

### Access tokens (your API)

Validate **locally** — fast, no network round trip per request:

1. Fetch JWKS from `{issuer}/v1/keys` (cache; keys rotate ~quarterly — auto-refetch on unknown `kid`).
2. Verify signature (RS256), `exp`/`iat` (allow small clock skew), `iss` equals your issuer exactly, `aud` equals your API's audience (set on the auth server / access policy; default server's default audience is `api://default`).
3. Enforce scopes from `scp` claim per endpoint.

Use the bundled verifier libraries (`sdk-catalog.md` §JWT verifiers) — they handle JWKS caching and rotation. Examples: `scripts/03-api-token-validation/`.

**Remote alternative**: `POST {issuer}/v1/introspect` (client-authenticated) returns `active: true/false` + claims. Use when you need revocation awareness; costs a network call per check.

**Org-server access tokens cannot be validated locally** — if `iss` is `https://{org}.okta.com` (no `/oauth2/{id}`), your API cannot verify it; that token is for Okta's own APIs.

### ID tokens

Same JWT checks with `aud` = your **client ID**, plus `nonce` if you sent one. SDKs do this automatically.

## Custom scopes and claims

On a custom authorization server:

- **Scopes**: define per API capability (`orders:read`, `orders:write`). Grant to clients via app grants/consent.
- **Claims**: add to ID and/or access tokens, sourced from Okta Expression Language, e.g. `user.email`, `user.profile.tier`, or a groups filter.
- **Groups claim**: common pattern — claim `groups`, value type Groups, filter regex `.*` (or a prefix filter to control size). For org-server ID tokens, use the app profile + static/dynamic allowlist patterns (guide: customize-tokens-groups-claim).
- Keep tokens small: filter group claims; don't stuff large profiles into every access token.

Terraform: `okta_auth_server_scope`, `okta_auth_server_claim` — see `assets/terraform-bootstrap/auth_server.tf`.

## Logout

- **Local app logout**: clear your session/token storage. The Okta session may persist (SSO will silently re-login).
- **RP-initiated logout**: redirect to `{issuer}/v1/logout?id_token_hint={idToken}&post_logout_redirect_uri={registered URI}` to also end the Okta session. Register the post-logout URI on the app.
- Revoke refresh tokens on logout for good hygiene: `POST {issuer}/v1/revoke`.

## Best practices checklist

- Always PKCE, even for confidential clients.
- Always validate `state`; use `nonce` for ID tokens.
- Exact-match redirect URIs; never wildcards in production.
- HTTPS-only redirect URIs (except `http://localhost` in dev).
- Store tokens appropriately: server session (web apps); memory + rotation (SPAs — avoid localStorage for refresh tokens where possible).
- Request only needed scopes; use `offline_access` deliberately.
- Custom auth server for your APIs; org server for Okta-API and plain sign-in.
- Short access-token lifetimes + refresh rotation over long-lived tokens.
